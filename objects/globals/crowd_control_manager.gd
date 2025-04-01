extends Node
const EFFECTS = preload("res://effects/effects.tres")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveFileService._save_progress()
		if CrowdControl.is_connected_to_crowd_control():
			CrowdControl.stop_session()
			CrowdControl.disconnected.connect(_on_CrowdControl_disconnected)
			CrowdControl.close()
		else:
			get_tree().quit()

func _on_CrowdControl_disconnected():
	get_tree().quit()



func make_all_effects_sellable():
	if CrowdControl.is_connected_to_crowd_control():
		for effect in EFFECTS.effects:
			effect.sellable = true

func make_all_effects_unsellable():
	if CrowdControl.is_connected_to_crowd_control():
		for effect in EFFECTS.effects:
			effect.sellable = false
