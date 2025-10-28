extends Node3D
class_name CrumblingPlatform

const ELEVATION_RANGE := Vector2(-0.04, 0.04)

@onready var physics_pieces: Node3D = %PhysicsPieces
@onready var base_model: Node3D = %Model

@export var player_crumble := false
@export var crumble_time := 1.0
@export var one_shot := true
@export var reset_time := 5.0
@export var crumble_strength := Vector3.ONE * 0.25
@export var custom_gravity_scale := 1.0

var crumble_verified := false
var player_inside := false


func _ready() -> void:
	%CrumbleTimer.wait_time = crumble_time
	%ResetTimer.wait_time = reset_time
	await get_tree().process_frame
	for i in physics_pieces.get_child_count():
		var body := physics_pieces.get_child(i)
		body.get_child(0).scale = base_model.get_child(i).scale / body.scale
	
	for i in base_model.get_child_count():
		var elevation := randf_range(ELEVATION_RANGE.x, ELEVATION_RANGE.y)
		base_model.get_child(i).position.y = elevation
		physics_pieces.get_child(i).position.y = elevation

func crumble() -> void:
	%SFXFallApart.pitch_scale += randf_range(-0.2, 0.2)
	%SFXFallApart.play()
	%StandCollision.set_deferred('disabled', true)
	base_model.hide()
	physics_pieces.show()
	
	var impulse_scale := 4.0
	for body: RigidBody3D in physics_pieces.get_children():
		body.gravity_scale = custom_gravity_scale
		
		# Get our impulse strength
		var node_center := NodeGlobals.calculate_spatial_bounds(body, false).get_center()
		var center_pos := body.global_position + node_center
		var origin := physics_pieces.global_position
		var pos_diff := center_pos - origin
		var impulse := crumble_strength * pos_diff
		impulse *= impulse_scale
		body.apply_central_impulse(impulse.rotated(Vector3(0, 1, 0), body.global_rotation.y))
		
		# Apply a random torque
		var torque_range := Vector2(-30.0, 30.0)
		var torque := []
		for i in 3: torque.append(randf_range(torque_range.x, torque_range.y))
		body.apply_torque_impulse(Vector3(deg_to_rad(torque[0]), deg_to_rad(torque[1]), deg_to_rad(torque[2])))
	
	%ResetTimer.start()

func body_entered(body: Node3D) -> void:
	if body is Player:
		player_inside = true

func body_exited(body: Node3D) -> void:
	if body is Player:
		player_inside = false

func activate_crumble() -> void:
	if crumble_verified: return
	crumble_verified = true
	%CrumbleTimer.start()
	
	var shakes := 40
	var z_start := base_model.position.z
	var shake_dist := 0.25
	var time_per_shake := (crumble_time * 0.8) / float(shakes)
	var shake_tween := create_tween()
	for i in shakes / 2:
		shake_tween.tween_property(base_model, 'position:z', shake_dist, time_per_shake)
		shake_tween.tween_property(base_model, 'position:z', z_start, time_per_shake)
	shake_tween.finished.connect(shake_tween.kill)

func on_timer_finished() -> void:
	crumble()

func reset() -> void:
	if one_shot:
		queue_free()
		return
	
	%StandCollision.set_deferred('disabled', false)
	base_model.show()
	
	# Reset the state of the rigid bodies
	for body: RigidBody3D in physics_pieces.get_children():
		body.gravity_scale = 0.0
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.position = Vector3.ZERO
		body.rotation = Vector3.ZERO
	
	physics_pieces.hide()

func _process(_delta: float) -> void:
	if not player_crumble: return
	if player_inside and not Util.get_player().state == Player.PlayerState.STOPPED and not crumble_verified:
		activate_crumble()
