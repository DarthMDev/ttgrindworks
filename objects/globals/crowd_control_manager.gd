extends Node 

const EFFECTS = preload("res://effects/effects.tres")

func _ready():
    if CrowdControl.is_connected_to_crowd_control() and not CrowdControl.is_session_active():
        CrowdControl.start_session()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        SaveFileService._save_progress()
        if CrowdControl.is_connected_to_crowd_control():
            CrowdControl.disconnected.connect(_on_CrowdControl_disconnected)
            CrowdControl.close()

func _on_CrowdControl_disconnected():
    get_tree().quit()