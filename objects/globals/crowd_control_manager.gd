extends Node
const EFFECTS = preload("res://effects/effects.tres")
# we have 3 neutral anomalies, 2 negative anomalies and 3 positive anomalies, 
const ANOMALIES = {
	"neutral": 3,
	"negative": 2,
	"positive": 3
}
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

func _process(_delta: float) -> void:
	# if we are not in a battle we should disable all effects related to battle (CCNerf and CCBuff , and in the future CCDOTEffect)
	if not BattleService.ongoing_battle:
		if CrowdControl.is_connected_to_crowd_control():
			for effect in EFFECTS.effects:
				if effect is CCNerf or effect is CCBuff:
					effect.sellable = false
			# set effects sellable stat to false since we are not in a battle
	else:
		if CrowdControl.is_connected_to_crowd_control():
			for effect in EFFECTS.effects:
				if effect is CCNerf or effect is CCBuff:
					effect.sellable = true
# TODO disable certain anomaly effects if we all of them 

func make_all_effects_sellable():
	if CrowdControl.is_connected_to_crowd_control():
		for effect in EFFECTS.effects:
			effect.sellable = true

func make_all_effects_unsellable():
	if CrowdControl.is_connected_to_crowd_control():
		for effect in EFFECTS.effects:
			effect.sellable = false
