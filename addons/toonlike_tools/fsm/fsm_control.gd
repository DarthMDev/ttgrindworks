@icon("res://addons/toonlike_tools/icons/diamond_green.png")
extends Control
class_name FiniteStateMachineControl
## A node that tracks and controls individual StateControl children.

#region State Registration

var states: Dictionary[StringName, StateControl] = {}

@export var initial_state: StateControl = null

func _enter_tree():
	child_entered_tree.connect(_add_state)
	child_exiting_tree.connect(_remove_state)

func _ready() -> void:
	for state in states.values():
		state._disable()
	if initial_state:
		initial_state.request()

func _add_state(s: Node):
	if s is StateControl:
		states[StringName(s.name)] = s

func _remove_state(s: Node):
	if s is StateControl:
		states.erase(StringName(s.name))

#endregion

#region State API

signal state_changed(state: StateControl)

var current_state: StateControl = null
var current_state_name := &""
var _in_transition := false

## Requests the current FSM state to change.
## No arguments will disable all states.
func request(n: StringName = &""):
	# Setup transition barrier.
	while _in_transition:
		await state_changed
	_in_transition = true
	
	# Poke transition requests.
	var next_state := get_state(n)
	if next_state == current_state:
		current_state._on_self_enter()
		_in_transition = false
		return
	if current_state and not current_state._poke_exit(next_state):
		_in_transition = false
		return
	if next_state and not next_state._poke_enter(current_state):
		_in_transition = false
		return
	
	# Perform transition.
	if current_state:
		current_state._exit(next_state)
		current_state._disable()
		current_state.exited.emit()
	if next_state:
		next_state._enter(current_state)
		next_state._enable()
		next_state.entered.emit()
	
	# Finalize state, unblock requests.
	#Log.info(self, "entering: %s" % n)
	current_state = next_state
	current_state_name = n
	_in_transition = false
	state_changed.emit(current_state)

func get_state(n: StringName) -> StateControl:
	return states.get(n, null)

#endregion
