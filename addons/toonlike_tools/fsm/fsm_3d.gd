@icon("res://addons/toonlike_tools/icons/diamond_red.png")
extends Node3D
class_name FiniteStateMachine3D
## A node that tracks and controls individual State children.

#region State Registration

var states: Dictionary[StringName, State3D] = {}

## When set to true, this FSM will set the visible property on state enable/disable.
@export var set_node_visibility := false

@export var initial_state: State3D = null

func _enter_tree():
	if not child_entered_tree.is_connected(_add_state):
		child_entered_tree.connect(_add_state)
		child_exiting_tree.connect(_remove_state)

func _ready() -> void:
	for state in states.values():
		if set_node_visibility: state.hide()
		state._disable()
	if initial_state:
		initial_state.request()

func _add_state(s: Node):
	if s is State3D:
		states[StringName(s.name)] = s

func _remove_state(s: Node):
	if s is State3D:
		states.erase(StringName(s.name))

#endregion

#region State API

signal state_changed(state: State3D)

var current_state: State3D = null
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
		if set_node_visibility: current_state.hide()
		current_state._exit(next_state)
		current_state._disable()
		current_state.exited.emit()
	if next_state:
		if set_node_visibility: next_state.show()
		next_state._enter(current_state)
		next_state._enable()
		next_state.entered.emit()
	
	# Finalize state, unblock requests.
	#Log.info(self, "entering: %s" % n)
	current_state = next_state
	current_state_name = n
	_in_transition = false
	state_changed.emit(current_state)

func get_state(n: StringName) -> State3D:
	return states.get(n, null)

func get_next_state() -> State3D:
	if not states:
		return null
	if not current_state:
		return get_child(0)
	else:
		var child_count := get_child_count()
		for idx in child_count - 1:
			if current_state == get_child(idx):
				return get_child(idx + 1)
		return null

#endregion
