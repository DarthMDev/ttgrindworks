extends Elevator



@export var seats: Array[Node3D] = []
@export var final_position: Vector3


func player_entered(player: Player) -> void:
	player.game_timer_tick = false
	s_elevator_entered.emit()
	
	# Stop the player
	player.state = Player.PlayerState.STOPPED
	CameraTransition.from_current(self, elevator_cam, 1.0)
	
	# Setup the jump path
	var seat_pos: Vector3 = get_seat(0).position + Vector3(-0.1, 0, 0)
	var first_sit_pos: Vector3 = seat_pos + Vector3(0, 0, 0.2)
	var global_seat_pos: Vector3 = to_global(seat_pos)
	var global_first_sit_pos: Vector3 = to_global(first_sit_pos)
	var path := get_jump_path(player.global_position, global_first_sit_pos, 1.35)
	var follower := PathFollow3D.new()
	follower.rotation_mode = PathFollow3D.ROTATION_NONE
	path.add_child(follower)
	player.reparent(follower)
	player.position = Vector3.ZERO
	player.rotation = Vector3.ZERO

	# Create the tween
	var cart_tween := create_tween()
	cart_tween.tween_callback(player.set_animation.bind('happy'))
	cart_tween.set_trans(Tween.TRANS_SINE)
	player.toon.rotation.y = fmod(player.toon.rotation.y, 360.0)
	cart_tween.parallel().tween_property(follower, 'progress_ratio', 1.0, 0.9).set_delay(0.43)
	cart_tween.parallel().tween_property(player.toon, 'rotation:y', 0.0, 0.9).set_delay(0.43)
	cart_tween.tween_callback(player.set_animation.bind('into_sit'))
	cart_tween.tween_interval(player.animator.get_animation(&"into_sit").length)
	cart_tween.tween_callback(func(): player.set_animation('sit'); player.global_position = global_seat_pos)
	cart_tween.tween_interval(1.0)
	cart_tween.tween_property(self, 'position', final_position, 5.0)
	cart_tween.parallel().tween_method(set_wheel_speed, 0.0, 100.0, 5.0)
	cart_tween.tween_callback(SceneLoader.add_persistent_node.bind(player))
	cart_tween.tween_callback(path.queue_free)
	cart_tween.tween_callback(player.set_global_rotation.bind(Vector3.ZERO))
	
	await cart_tween.finished
	cart_tween.kill()
	SceneLoader.change_scene_to_file(scene_path)

func get_seat(index: int) -> Node3D:
	if index >= seats.size():
		return null
	return seats[index]

func get_jump_path(from: Vector3, to: Vector3, height := 2.0) -> Path3D:
	# Create the path and curve
	var path = Path3D.new()
	var curve := Curve3D.new()
	add_child(path)
	path.curve = curve
	curve.bake_interval = 2.0
	
	# Get the midpoint
	var midpt := (from + to) / 2.0
	
	# Add height to midpoint
	midpt.y += height
	
	# Add the point
	var points: Array[Vector3] = [from, midpt, to]
	for point in points:
		path.global_position = point
		curve.add_point(path.position)
	path.position = Vector3.ZERO
	
	# Return the new path node
	return path


var wheel_speed := 0.0
func set_wheel_speed(spd : float) -> void:
	wheel_speed = spd

func _process(delta : float) -> void:
	var mat : StandardMaterial3D = $cgc_cart/suspensionNode/main_geometry/wheelNode1/leftFrontWheel.get_surface_override_material(0)
	mat.uv1_offset.y += wheel_speed * delta
