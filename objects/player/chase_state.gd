extends PlayerState3D

func handle_movement(delta: float) -> void:
	handle_jump(delta)
	apply_gravity(delta)
	capture_mouse()

	var current_camera: Camera3D = get_viewport().get_camera_3d()
	sprint = true
	speed = get_run_speed()
	_movement_style_standard(delta, current_camera)
	
	player.move_and_slide()

func accepts_interaction() -> bool:
	return true
