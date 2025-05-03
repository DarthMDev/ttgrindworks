extends Node3D

const LIGHT_MAT := preload("res://objects/obstacles/spotlight/spotlight_mat.tres")
const COLOR_ALERT := Color("ff00001a")
const COLOR_STANDARD := Color("ffffff0d")
const SFX_TRIPPED := preload("res://audio/sfx/objects/spotlight/LB_laser_beam_on_2.ogg")
const SFX_RESET := preload("res://audio/sfx/objects/spotlight/LB_laser_beam_off_2.ogg")

@export var light_path: Path3D
@export var origin_path: Path3D
@export var light_radius := 2.5
@export var base_damage := -1
@export var light_spd := 0.25
@export var wait_range := Vector2(0.0 , 5.0)

@onready var light: MeshInstance3D = $Spotlight
@onready var light_follower: PathFollow3D = $Spotlight/PathFollow3D
@onready var origin: Node3D = $Origin
@onready var origin_follower: PathFollow3D = $Origin/PathFollow3D
@onready var beam: MeshInstance3D = $Origin/stomper/Beam
@onready var player_detection: Area3D = $Spotlight/PlayerDetection
@onready var collision_shape: CollisionShape3D = $Spotlight/PlayerDetection/CollisionShape3D
@onready var sfx_alert: AudioStreamPlayer3D = $SFXAlert
@onready var sfx_move: AudioStreamPlayer3D = $SFXMove
@onready var sfx_trip: AudioStreamPlayer3D = $SFXTrip
@onready var pause_timer: Timer = $PauseTimer

var light_moving := false
var origin_moving := false
var light_mesh: GeneratedMesh
var beam_mesh: GeneratedMesh
var mesh_mat: StandardMaterial3D
var damage: int


func _ready() -> void:
	# Create the light material
	mesh_mat = LIGHT_MAT.duplicate()
	
	if light_path:
		set_light_path(light_path)
	if origin_path:
		set_origin_path(origin_path)
	
	light_mesh = get_circle_points(16, 0, 0, light_radius)
	light.mesh = light_mesh.to_mesh()
	light.mesh.surface_set_material(0,mesh_mat)
	
	collision_shape.shape = collision_shape.shape.duplicate()
	collision_shape.shape.radius = light_radius
	
	damage = Util.get_hazard_damage() + base_damage

func _physics_process(delta: float) -> void:
	if light_moving:
		light_follower.progress_ratio += light_spd * delta
		light.position = light_follower.position
		
		if path_end_reached(light_spd,light_follower.progress_ratio):
			light_spd = -light_spd
			light_pause()
	
	if origin_moving:
		origin_follower.progress_ratio += delta
		origin.position = origin_follower.position
	
	if light_moving or origin_moving:
		rotate_origin()
		origin.rotation_degrees.x += 90.0
		origin.rotation_degrees.z += 180.0
	
	if light_mesh:
		reset_beam()

func light_pause() -> void:
	light_moving = false
	sfx_move.stop()
	pause_timer.start(RandomService.randf_range_channel("true_random", wait_range.x, wait_range.y))
	await pause_timer.timeout
	light_moving = true
	sfx_move.play()

func reset_beam() -> void:
	beam_mesh = GeneratedMesh.new()
	beam_mesh.primitive_type = Mesh.PRIMITIVE_TRIANGLE_STRIP
	
	# Get positional offset
	var pos_offset := light.global_position - beam.global_position
	
	for vert: Vector3 in light_mesh.vertices:
		if vert.is_equal_approx(Vector3(0, 0, 0)):
			continue
		beam_mesh.vertices.append(Vector3(0, 0, 0))
		beam_mesh.vertices.append(vert + pos_offset)
	
	# Always reset beam's rotation so that its measurements are accurate
	beam.global_rotation = Vector3.ZERO
	
	# Apply the mesh to the instance
	var mesh := beam_mesh.to_mesh()
	mesh.surface_set_material(0, mesh_mat)
	beam.mesh = mesh

func set_light_path(path: Path3D) -> void:
	path.reparent(light)
	light_follower.reparent(path)
	light_moving = true

func set_origin_path(path: Path3D) -> void:
	path.reparent(origin)
	origin_follower.reparent(path)
	origin_moving = true

## Generates the spotlight mesh
func get_circle_points(seg_count: int, center_x: float, center_y: float, radius: float, wide_x := 1.0, wide_y := 1.0) -> GeneratedMesh:
	var return_mesh := GeneratedMesh.new()
	return_mesh.primitive_type = Mesh.PRIMITIVE_TRIANGLE_STRIP
	
	for seg: int in seg_count:
		var coord_x := wide_x * (circle_x(((PI * 2.0) * float(float(seg) / float(seg_count))), radius, center_x))
		var coord_y := wide_y * (circle_y(((PI * 2.0) * float(float(seg) / float(seg_count))), radius, center_y))
		return_mesh.vertices.append(Vector3(coord_x, 0, coord_y))
		return_mesh.vertices.append(Vector3(0, 0, 0))
	
	var x_coord := wide_x * (circle_x(((PI * 2.0) * float(0.0 / float(seg_count))), radius, center_x))
	var y_coord := wide_y * (circle_y(((PI * 2.0) * float(0.0 / float(seg_count))), radius, center_y))
	return_mesh.vertices.append(Vector3(x_coord, 0, y_coord))
	
	return return_mesh

func circle_x(angle: float, radius: float, center_x: float) -> float:
	return radius * cos(angle) + center_x

func circle_y(angle: float, radius: float, center_y: float) -> float:
	return radius * sin(angle) + center_y

func body_entered(body: Node3D) -> void:
	if body is Player:
		if body.immune_to_light_damage:
			Util.do_3d_text(body, "Undetected!", BattleText.colors.orange[0], BattleText.colors.orange[1])
		else:
			alert(body)

func alert(player: Player) -> void:
	player_detection.set_monitoring.call_deferred(false)
	
	# Play associated sfx
	sfx_alert.play()
	play_sfx(sfx_trip, SFX_TRIPPED)
	
	player.last_damage_source = "a Spotlight"
	player.quick_heal(damage)
	
	var alert_tween := create_tween()
	alert_tween.tween_property(mesh_mat, "albedo_color", COLOR_ALERT, 1.0)
	alert_tween.tween_property(mesh_mat, "albedo_color", COLOR_STANDARD, 1.0)
	alert_tween.finished.connect(
		func():
			alert_tween.kill()
			player_detection.set_monitoring(true)
			
			# Stop alert sfx,
			# Play reset sfx
			sfx_alert.stop()
			play_sfx(sfx_trip, SFX_RESET)
	)

## Tests if the path end was reached
func path_end_reached(spd: float, progress_ratio: float) -> bool:
	match int(signf(spd)):
		1: 
			return progress_ratio >= 1.0
		_: 
			return progress_ratio <= 0.0

## Absolute bandage fix version of look_at so it stops throwing errors
func rotate_origin() -> void:
	var target := light.global_position + Vector3(0.001, 0.001, 0.001)
	origin.look_at(target)

## Plays a given sound effect
func play_sfx(sfx_player: AudioStreamPlayer3D, sfx: AudioStream) -> void:
	sfx_player.set_stream(sfx)
	sfx_player.play()
