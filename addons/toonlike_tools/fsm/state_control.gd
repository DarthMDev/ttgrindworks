@icon("res://addons/toonlike_tools/icons/diamond_purple.png")
extends Control
class_name StateControl
## A node whose functionality is determined by its parent fsm.

signal entered  # emitted through FSM
signal exited   # emitted through FSM

@onready var fsm: FiniteStateMachineControl = get_parent()

var state_name: StringName:
	get: return StringName(name)

func _ready() -> void:
	pass

func _enter(_prev: StateControl):
	pass

func _exit(_next: StateControl):
	pass

## Pokes the state and asks if we can enter into it.
## A transition is cancelled if this returns false.
func _poke_enter(_prev: StateControl) -> bool:
	return true

## Pokes the state and asks if we can exit from it.
## A transition is cancelled if this returns false.
func _poke_exit(_next: StateControl) -> bool:
	return true

## Called when this state attempts to re-enter itself.
func _on_self_enter():
	pass

func _disable():
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	hide()

func _enable():
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	show()

func request():
	fsm.request(state_name)
