extends PlayerState3D

func handle_movement(delta: float) -> void:
	capture_mouse()

	handle_jump(delta)
	handle_default_movement(delta)
	debug_collision_check()

	handle_camera()

func accepts_interaction() -> bool:
	return true
