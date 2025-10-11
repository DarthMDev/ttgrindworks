@tool
extends StatusEffect


func apply() -> void:
	target.stats.turns += 1
	manager.battle_stats[target].damage *= 0.7
