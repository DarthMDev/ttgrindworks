@tool
extends StatusEffect

const DAMAGE_NERF_RATE := -0.05
const STAT_BOOST := "res://objects/battle/battle_resources/status_effects/resources/mod_cog_interference_toon.tres"

var toon_effect: StatBoost


func get_status_name() -> String:
	return "Interference"

func get_descriptioin() -> String:
	return "Inflicts -5% Damage on the player for every Cog in battle"

func apply() -> void:
	toon_effect = load(STAT_BOOST).duplicate(true)
	toon_effect.rounds = -1
	toon_effect.target = Util.get_player()
	manager.s_participant_joined.connect(on_participants_changed)
	manager.s_participant_died.connect(on_participants_changed)
	refresh_effect(toon_effect)
	manager.add_status_effect(toon_effect)

func on_participants_changed(_p) -> void:
	if toon_effect:
		refresh_effect(toon_effect)

func refresh_effect(effect: StatBoost) -> void:
	effect.boost = (DAMAGE_NERF_RATE * manager.cogs.size())

func cleanup() -> void:
	manager.expire_status_effect(toon_effect)
