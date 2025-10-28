extends PlayerState3D

var push_object: PushableComponent
var start_input: Vector2
var dom_axis: int
var both_axis_dom: bool

func _enter(_prev: State3D):
	# if not
	push_object.assign_player(owner)
	toon.rotation.y = push_object.face_direction
	
	start_input = _get_abs_input()
	if start_input[Vector2.AXIS_X] == start_input[Vector2.AXIS_Y]:
		dom_axis = Vector2.AXIS_X
		both_axis_dom = true
	else:
		dom_axis = start_input.max_axis_index()
		both_axis_dom = false
	
func _exit(_next: State3D):
	push_object.clear_player()
	push_object = null

func _get_abs_input() -> Vector2:
	if control_style:
		return Input.get_vector("move_left", "move_right", "move_forward", "move_back").abs()
	else:
		return Input.get_vector("", "", "move_forward", "move_back").abs()

func handle_movement(delta: float) -> void:
	capture_mouse()
	apply_gravity(delta)
	
	moving = true
	var push_speed := get_run_speed() / 3.0
	
	if start_input[dom_axis] - _get_abs_input()[dom_axis] >= start_input[dom_axis]:
		if both_axis_dom:
			dom_axis = Vector2.AXIS_Y
			both_axis_dom = false
		else:
			player.state = Player.PlayerState.WALK
			return
	
	push_object.do_push(push_speed * delta)
	
	handle_camera()

func assess_anim() -> void:
	var anim := 'push'
	if not get_animation() == anim:
		set_animation(anim)

func accepts_interaction() -> bool:
	return true
