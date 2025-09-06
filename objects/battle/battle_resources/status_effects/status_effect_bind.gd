@tool
extends StatusEffect




func apply() -> void:
	print("$$$$$$$$$$$$$$$$$$$$$$$$")
	manager.s_battle_ending.connect(expire_status)
	print("BIND LINE 9 IN APPLY WHAT IS HAPPEDN?!")
	disable_items()
	if manager.current_round < 1:
		manager.s_ui_initialized.connect(disable_items)
	else: manager.s_round_ended.connect(disable_items)
	print("HHHHHEEEEEELLLLLLOOOOOOO WHAT IS GOING ONNNNN")

func expire() -> void:
	cleanup()
	manager.battle_ui.enable_items()
func disable_items() -> void:
	manager.battle_ui.disable_items()
func expire_status() -> void:
	manager.expire_status_effect(self)
func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/red_tape.png")
func cleanup() -> void:
	if manager.s_round_ended.is_connected(disable_items):
		manager.s_round_ended.disconnect(disable_items)
	if manager.s_ui_initialized.is_connected(disable_items):
		manager.s_ui_initialized.disconnect(disable_items)
	
