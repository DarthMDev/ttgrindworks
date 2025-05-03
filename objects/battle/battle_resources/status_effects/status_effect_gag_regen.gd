@tool
extends StatusEffect
class_name StatusEffectGagRegen

@export var amount := 1

func apply() -> void:
	var stats : PlayerStats = target.stats
	for track in stats.gag_regeneration:
		stats.gag_regeneration[track] += amount
	manager.s_battle_ending.connect(cleanup)

func cleanup() -> void:
	if not target:
		return
	var stats : PlayerStats = target.stats
	for track in stats.gag_regeneration:
		stats.gag_regeneration[track] -= amount
	amount = 0
	manager.s_battle_ending.disconnect(cleanup)

func combine(effect : StatusEffect) -> bool:
	if effect.status_name == status_name and effect.rounds == rounds:
		amount += effect.amount
		return true
	return false

func get_description() -> String:
	return "+%d Gag point regeneration" % amount
