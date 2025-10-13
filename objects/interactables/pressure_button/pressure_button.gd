@tool
extends CogButton
class_name PressureButton

var disabled := false

func _ready() -> void:
	super()

func body_entered(body : Node3D) -> void:
	if not disabled and body is Player and body.controller.current_state.accepts_interaction():
		press()

func body_exited(body : Node3D) -> void:
	if not disabled and body is Player:
		retract()

func disable() -> void:
	press(false)
	disabled = true
