@tool
extends StatusEffect
class_name StatusEffectGagDiscount

@export var discount := 1

func apply() -> void:
	var stats: PlayerStats = manager.battle_stats[target]
	stats.gag_discount += discount
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		track.refresh()

func get_description() -> String:
	if signi(discount) == -1:
		if discount == -1:
			return "Gags cost 1 point more"
		else:
			return "Gags cost %s points more" % absi(discount)
	
	if discount == 1:
		return "Gags cost 1 point less"
	return "Gags cost %s points fewer" % discount

func get_status_name() -> String:
	if signi(discount) == -1:
		return "Price Hike"
	return "Gag Discount"

func cleanup() -> void:
	if not target: return
	var stats: PlayerStats = manager.battle_stats[target]
	stats.gag_discount -= discount
	for track: TrackElement in manager.battle_ui.gag_tracks.get_children():
		track.refresh()

func combine(effect: StatusEffect) -> bool:
	if effect.get_script() == get_script() and rounds == effect.rounds and signi(discount) == signi(effect.discount):
		cleanup()
		discount += effect.discount
		apply()
		return true
	return false
