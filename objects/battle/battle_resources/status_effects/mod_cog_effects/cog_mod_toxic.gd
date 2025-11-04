@tool
extends StatusEffect

var player: Player:
	get: return Util.get_player()
var player_hp := 0

const EFFECTS: Dictionary[String, String] = {
	"stat_boost": "res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres",
	"gag_discount": "res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_discount.tres",
	"poison": "res://objects/battle/battle_resources/status_effects/resources/status_effect_poison.tres",
	"aftershock": "res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres",
	"budget_cuts": "res://objects/battle/battle_resources/status_effects/resources/status_effect_budget_cuts.tres",
}

func apply() -> void:
	player_hp = player.stats.hp
	player.stats.hp_changed.connect(on_hp_change)

func on_hp_change(new_hp: int) -> void:
	if new_hp < player_hp and is_target_attacking():
		apply_random_effect()
	player_hp = new_hp

func is_target_attacking() -> bool:
	if not manager.current_action: return false
	
	return manager.current_action.user == target

func apply_random_effect() -> void:
	var effect_tag: String = EFFECTS.keys().pick_random()
	apply_effect(effect_tag)

func apply_effect(effect_tag: String) -> void:
	var effect: StatusEffect = load(EFFECTS[effect_tag]).duplicate(true)
	effect.target = player
	effect.randomize_effect()
	effect.quality = EffectQuality.NEGATIVE
	
	match effect_tag:
		"gag_discount": effect.discount = -1
		"stat_boost": effect.boost = -absf(effect.boost)
		"budget_cuts": 
			effect.track_name = get_random_track().track_name
			if player.gags_cost_beans: effect.penalty = 1
	
	manager.add_status_effect(effect)

func cleanup() -> void:
	player.stats.hp_changed.disconnect(on_hp_change)

func get_random_track() -> Track:
	return player.stats.character.gag_loadout.loadout.pick_random()
