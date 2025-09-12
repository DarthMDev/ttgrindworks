@tool
extends StatusEffect

var cog_hps : Dictionary[Cog, int] = {}
var cog_connections : Dictionary[Cog, Callable] = {}
const  Stat_Boost: StatusEffect = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
func apply() -> void:
	for cog in manager.cogs:
		hookup_cog(cog)
	manager.s_participant_joined.connect(func(participant): if participant is Cog: hookup_cog(participant))
	manager.s_status_effect_added.connect(on_status_effect_added)




func get_status_name() -> String:
	return "Cohesive"
	
const RANDOM_EFFECTS : Array[StatusEffect] = [
	Stat_Boost,
	preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_regeneration.tres"),
	Stat_Boost,
]


func hookup_cog(cog : Cog) -> void:
	cog_hps[cog] = cog.stats.hp
	var callable := cog_hp_changed.bind(cog)
	cog.stats.hp_changed.connect(callable)
	cog_connections[cog] = callable

func cog_hp_changed(hp : int, cog : Cog) -> void:
	if cog in cog_hps.keys() and is_instance_valid(BattleService.ongoing_battle):
		if cog_hps[cog] >= hp and cog in BattleService.ongoing_battle.cogs:
			if BattleService.ongoing_battle.current_action is ToonAttack:
				apply_random_effect(cog)
		cog_hps[cog] = hp

func apply_random_effect(cog : Cog) -> void:
	if not target:
		return
	var effect : StatusEffect = RandomService.array_pick_random('true_random', RANDOM_EFFECTS).duplicate()
	effect.target = cog
	if effect is StatBoost:
		tweak_stat_boost(effect)
		effect.boost = RandomService.randf_range_channel('true_random', 1.12, 1.20)
		effect.quality = StatusEffect.EffectQuality.POSITIVE
		effect.rounds = 2
	elif effect is StatEffectRegeneration:
		effect.instant_effect = false
		effect.rounds = 0
		if target:
			effect.amount = ceili(target.stats.max_hp * 0.14)
	await Util.s_process_frame
	BattleService.ongoing_battle.add_status_effect(effect)

func tweak_stat_boost(effect : StatBoost) -> void:
	var valid_effects := ["defense", "damage"]
	if effect.stat not in valid_effects:
		effect.stat = RandomService.array_pick_random('true_random', valid_effects)

func on_status_effect_added(effect : StatusEffect) -> void:
	if effect is StatusLured:
		apply_random_effect(effect.target)
func cleanup() -> void:
	for cog in cog_connections:
		if is_instance_valid(cog) and cog.stats:
			cog.stats.hp_changed.disconnect(cog_connections[cog])
	cog_connections.clear()
	cog_hps.clear()
