@tool
extends StatusEffect
const Curse_Status_Reference := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_bind.tres")


func apply() -> void:
	var status_effect := Curse_Status_Reference.duplicate()
	status_effect.target = Util.get_player()
	status_effect.rounds = 0
	#manager.add_status_effect(status_effect)

	

func on_death() -> void:
	pass

func renew() -> void:
	var status_effect := Curse_Status_Reference.duplicate()
	status_effect.target = Util.get_player()
	status_effect.rounds = 0
	manager.add_status_effect(status_effect)
	


func get_status_name() -> String:
	return "Red Tape"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/red_tape.png")
