extends ToonAttack
class_name ToonUp

const SFX_USE := preload("res://audio/sfx/battle/gags/MG_pos_buzzer.ogg")
const SFX_LADDER := preload("res://audio/sfx/battle/gags/delighted_06.ogg")
const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
const REGEN_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_regeneration.tres")


enum MovieType {
	FEATHER,
	MEGAPHONE,
	LIPSTICK,
	CANE,
	PIXIE,
	JUGGLING,
	LADDER
}

const MovieTypeToLevel: Dictionary = {
	MovieType.FEATHER: 0,
	MovieType.MEGAPHONE: 1,
	MovieType.LIPSTICK: 2,
	MovieType.CANE: 3,
	MovieType.PIXIE: 4,
	MovieType.JUGGLING: 5,
	MovieType.LADDER: 6,
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
			BattleService.ongoing_battle.add_status_effect(stat_effect)
	else:
		sfx = SFX_USE
		if status_effect:
			var new_effect: StatusEffect = get_status_effect_copy(status_effect)
			new_effect.target = target
			if movie_type == MovieType.PIXIE:
				new_effect.amount = ceili(target.stats.max_hp * 0.2)
				BattleService.ongoing_battle.affect_target(target, -new_effect.amount)
			BattleService.ongoing_battle.add_status_effect(new_effect)
		elif movie_type == MovieType.LIPSTICK:
			BattleService.ongoing_battle.affect_target(target, -(target.stats.max_hp * 0.4))

	var unite: GPUParticles3D = load('res://objects/battle/effects/unite/unite.tscn').instantiate()
	Util.get_player().add_child(unite)
	AudioManager.play_sound(Util.get_player().toon.yelp)
	AudioManager.play_sound(sfx)
	BattleService.s_refresh_statuses.emit()

const ALL_STATS_UP_STATS := {
	'luck': 1.1,
	'damage': 1.05,
	'defense': 1.1,
	'evasiveness': 1.1,
}

func get_ladder_effects() -> Array[StatusEffect]:
	var status_effects: Array[StatusEffect] = []
	for stat: String in ALL_STATS_UP_STATS.keys():
		var stat_effect := STAT_BOOST_REFERENCE.duplicate()
		stat_effect.stat = stat
		stat_effect.boost = ALL_STATS_UP_STATS[stat]
		status_effects.append(stat_effect)
		stat_effect.rounds = 2
	return status_effects

func get_toonup_level() -> int:
	return MovieTypeToLevel[movie_type]

## Get properly registered version of stat boost
func get_stat_boost(stat_boost: StatBoost) -> StatBoost:
	var new_boost := STAT_BOOST_REFERENCE.duplicate()
	new_boost.quality = stat_boost.quality
	new_boost.stat = stat_boost.stat
	new_boost.boost = stat_boost.boost
	new_boost.rounds = 2
	return new_boost

## Get properly registered version of regeneration
func get_regen(regen: StatEffectRegeneration) -> StatEffectRegeneration:
	var new_regen := REGEN_REFERENCE.duplicate()
	new_regen.status_name = "Pixie Dust"
	new_regen.amount = regen.amount
	new_regen.instant_effect = regen.instant_effect
	new_regen.rounds = 2
	new_regen.icon = load("res://ui_assets/battle/statuses/investment_cog_heal.png")
	new_regen.description = "%s%% laff regeneration" % roundi(20.0 * Util.get_player().stats.healing_effectiveness)
	return new_regen

## Get properly registered version of toonup effect.
func get_status_effect_copy(base_effect: StatusEffect) -> StatusEffect:
	if base_effect is StatBoost:
		return get_stat_boost(base_effect)
	elif base_effect is StatEffectRegeneration:
		return get_regen(base_effect)
	return base_effect
