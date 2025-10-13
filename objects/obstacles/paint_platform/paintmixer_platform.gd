@tool
extends AnimatableBody3D

enum TextureType { PAINT, REGULAR }

const EDGE_PAINT_MAT := preload("res://objects/obstacles/paint_platform/edge_paint_mat.tres")
const EDGE_REGULAR_MAT := preload("res://objects/obstacles/paint_platform/edge_regular_mat.tres")

@export var texture_type := TextureType.PAINT:
	set(x):
		texture_type = x
		await NodeGlobals.until_ready(self)
		update_texture()

@export var speed := 3.0
@export var loop_wait_delay := 0.0
@export var trans_type := Tween.TransitionType.TRANS_QUAD
@export var shaft_length := 1.0:
	set(x):
		shaft_length = x
		await NodeGlobals.until_ready(self)
		%PaintMixerBase.scale.z = 0.01 * shaft_length
		%ShaftCollide.scale.z = 0.01 * shaft_length

@export var points: Array[Vector3] = []

@onready var top: MeshInstance3D = %PaintMixerTop_001

var index := 0

# Create a tween to loop through 
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	if not points:
		return

	points = points.duplicate(true)
	
	points.append(position)
	
	# Setup
	var move_tween := create_tween()
	move_tween.set_loops()
	move_tween.set_trans(trans_type)
	
	for point in points:
		move_tween.tween_property(self, 'position', point, speed)
	if not is_equal_approx(loop_wait_delay, 0.0):
		move_tween.tween_interval(loop_wait_delay)

	# When generated this way, synced to physics
	# The object spawns relative to the world origin
	# Then quickly corrects itself.
	# Until I find a better solution
	# Hide object for 3 seconds before showing again
	hide()
	$TopCollide.set_deferred("disabled", true)
	$ShaftCollide.set_deferred("disabled", true)
	await get_tree().create_timer(speed).timeout
	show()
	$TopCollide.set_deferred("disabled", false)
	$ShaftCollide.set_deferred("disabled", false)

func _process(_delta):
	if Engine.is_editor_hint():
		return
	# There is a bug that causes these platforms to go wacky bonkers
	# So this forces their rotation to not go wacky bonkers
	if points:
		global_rotation.y = 0.0
	else:
		position = Vector3.ZERO

func update_texture() -> void:
	top.set_surface_override_material(0, EDGE_PAINT_MAT if texture_type == TextureType.PAINT else EDGE_REGULAR_MAT)
