extends "res://objects/modules/mint/variants/golden_goose_obj.gd"


func press_area_body_entered(body: Node3D) -> void:
	if body is Player:
		%Button.press()

func is_button() -> bool:
	return true

func is_pressed() -> bool:
	return %Button.pressed
