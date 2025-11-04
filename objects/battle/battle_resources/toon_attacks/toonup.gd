extends ToonAttack
class_name ToonUp

const SFX_USE := preload("res://audio/sfx/battle/gags/MG_pos_buzzer.ogg")
const SFX_LADDER := preload("res://audio/sfx/battle/gags/delighted_06.ogg")
const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
const REGEN_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_regeneration.tres")
const GAG_DISCOUNT_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_discount.tres")
const BASE_ROUND_COUNT := 1

enum MovieType {
	FEATHER = 0,
	MEGAPHONE = 1,
	LIPSTICK = 2,
	CANE = 3,
	PIXIE = 4,
	JUGGLING = 5,
	LADDER = 6,
}

@export var movie_type := MovieType.FEATHER
@export var custom_description: String
@export var status_effect: StatusEffect

func apply(target: Player) -> void:
	var sfx: AudioStream
	if movie_type == MovieType.LADDER:
		sfx = SFX_LADDER
		for stat_effect in get_ladder_effects():
			stat_effect.target = target
			if not is_equal_approx(target.stats.toonup_boost, 1.0):
				stat_effect.boost *= target.stats.toonup_boost
			BattleService.ongoing_battle.add_status_effect(stat_effect)
	else:
		sfx = SFX_USE
		if status_effect:
			var new_effect: StatusEffect = get_status_effect_copy(status_effect)
			new_effect.is_toonup_effect = true
			new_effect.force_no_combine = true
			new_effect.target = target
			if not is_equal_approx(target.stats.toonup_boost, 1.0):
				if new_effect is StatBoost:
					new_effect.boost *= target.stats.toonup_boost
				elif new_effect is StatusEffectGagDiscount:
					new_effect.discount = roundi(float(new_effect.discount) * target.stats.toonup_boost)
			if not try_combine(new_effect):
				BattleService.ongoing_battle.add_status_effect(new_effect)

	var unite: GPUParticles3D = load('res://objects/battle/effects/unite/unite.tscn').instantiate()
	Util.get_player().add_child(unite)
	AudioManager.play_sound(Util.get_player().toon.yelp)
	AudioManager.play_sound(sfx)
	BattleService.s_refresh_statuses.emit()

const ALL_STATS_UP_STATS := {
	'damage': 0.15,
	'luck': 0.2,
	'defense': 0.35,
	'evasiveness': 0.35,
}

func get_ladder_effects() -> Array[StatusEffect]:
	var status_effects: Array[StatusEffect] = []
	for stat: String in ALL_STATS_UP_STATS.keys():
		var stat_effect := STAT_BOOST_REFERENCE.duplicate(true)
		stat_effect.stat = stat
		stat_effect.quality = StatusEffect.EffectQuality.POSITIVE
		stat_effect.boost = ALL_STATS_UP_STATS[stat]
		stat_effect.rounds = BASE_ROUND_COUNT + Util.get_player().stats.toonup_round_boost
		stat_effect.is_toonup_effect = true
		stat_effect.force_no_combine = true
		if not try_combine(stat_effect):
			status_effects.append(stat_effect)
	return status_effects

func get_toonup_level() -> int:
	return movie_type as int

## Get properly registered version of stat boost
func get_stat_boost(stat_boost: StatBoost) -> StatBoost:
	var new_boost := STAT_BOOST_REFERENCE.duplicate(true)
	new_boost.quality = stat_boost.quality
	new_boost.stat = stat_boost.stat
	new_boost.boost = stat_boost.boost
	new_boost.rounds = BASE_ROUND_COUNT + Util.get_player().stats.toonup_round_boost
	return new_boost

## Get properly registered version of regeneration
func get_regen(regen: StatEffectRegeneration) -> StatEffectRegeneration:
	var new_regen := REGEN_REFERENCE.duplicate(true)
	new_regen.status_name = "Pixie Dust"
	new_regen.amount = regen.amount
	new_regen.instant_effect = regen.instant_effect
	new_regen.rounds = BASE_ROUND_COUNT + Util.get_player().stats.toonup_round_boost
	new_regen.icon = load("res://ui_assets/battle/statuses/investment_cog_heal.png")
	new_regen.description = "%s%% laff regeneration" % roundi(20.0 * Util.get_player().stats.healing_effectiveness)
	new_regen.amount = ceili(Util.get_player().stats.max_hp * 0.2 * Util.get_player().stats.toonup_boost)
	new_regen.description = "%.d%% Laff Regeneration" % (0.2 * Util.get_player().stats.toonup_boost * 100)
	BattleService.ongoing_battle.affect_target(Util.get_player(), -new_regen.amount)
	return new_regen

## Gets properly registered version of gag discount boost
func get_gag_discount(_base_effect: StatusEffectGagDiscount) -> StatusEffect:
	var new_effect := GAG_DISCOUNT_REFERENCE.duplicate(true)
	new_effect.discount = 2
	new_effect.rounds = BASE_ROUND_COUNT + Util.get_player().stats.toonup_round_boost
	return new_effect

func get_life_insurance() -> StatusEffect:
	var effect: StatusEffect = GameLoader.load("res://objects/battle/battle_resources/status_effects/resources/status_effect_life_insurance.tres").duplicate(true)
	effect.target = Util.get_player()
	effect.rounds = 0 + Util.get_relevant_player_stats().toonup_round_boost
	return effect

## Get properly registered version of toonup effect.
func get_status_effect_copy(base_effect: StatusEffect) -> StatusEffect:
	if base_effect is StatBoost:
		return get_stat_boost(base_effect)
	elif base_effect is StatEffectRegeneration:
		if Util.get_player().revives_are_hp:
			return get_life_insurance()
		return get_regen(base_effect)
	elif base_effect is StatusEffectGagDiscount:
		return get_gag_discount(base_effect)
	return base_effect.duplicate(true)

func try_combine(new_effect: StatusEffect) -> bool:
	# For stat boosts we also take the highest value
	if new_effect is StatBoost:
		for effect in BattleService.ongoing_battle.get_statuses_for_target(Util.get_player()):
			if not effect.is_toonup_effect: continue
			if effect is StatBoost:
					if effect.stat == new_effect.stat:
						effect.rounds += new_effect.rounds + 1
						effect.expire()
						effect.boost = maxf(effect.boost, new_effect.boost)
						effect.apply()
						return true
	else:
		for effect in BattleService.ongoing_battle.get_statuses_for_target(Util.get_player()):
			if effect.is_toonup_effect and effect.id == new_effect.id:
				effect.rounds += new_effect.rounds + 1
				return true
	
	return false
