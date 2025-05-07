@tool
extends StatusEffect

@export var discount := 1

func apply() -> void:
	var stats : PlayerStats = manager.battle_stats[target]
	stats.gag_discount += discount
	for track : TrackElement in manager.battle_ui.gag_tracks.get_children():
		track.refresh()

func get_description() -> String:
	if discount == 1:
		return "Gags cost 1 fewer point"
	return "Gags cost %s fewer points" % discount

func cleanup() -> void:
	if not target: return
	var stats : PlayerStats = manager.battle_stats[target]
	stats.gag_discount -= discount
	for track : TrackElement in manager.battle_ui.gag_tracks.get_children():
		track.refresh()

func combine(effect : StatusEffect) -> bool:
	if effect.get_script() == get_script() and rounds == effect.rounds:
		cleanup()
		discount += effect.discount
		apply()
		return true
	return false
