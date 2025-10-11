extends Control
class_name Control3D
## A control that fixates on a point in the 3D scene.

@export var target: Node3D:
	set(x):
		target = x
		await NodeGlobals.until_ready(self)
		_update()
@export var show_through := true:
	set(x):
		show_through = x
		await NodeGlobals.until_ready(self)
		_update()
@export var force_hide := false

## Should we use physics process for this?
@export var use_physics_process: bool = false:
	set(x):
		use_physics_process = x
		if is_node_ready():
			set_process(not use_physics_process)
			set_physics_process(use_physics_process)

@export_category("Scaling")
## What is the min scale of this Thing?
@export var min_scale: float = 0.1
## What is the max scale of this Thing?
@export var max_scale: float = 1.0
## How close to the target does the max scale occur at?
@export var min_dist: float = 0.0:
	set(x):
		min_dist = x
		set_diffy()
## How far away from the target does the min scale occur at?
@export var max_dist: float = 50.0:
	set(x):
		max_dist = x
		set_diffy()

@export_category("Screen Offset")
## Whats the min position offset of the control?
@export var min_screen_offset := Vector2(0, 0)
## Whats the max position offset of the control?
@export var max_screen_offset := Vector2(0, 0)
## How close to the target does the max offset occur at?
@export var screen_offset_min_dist: float = 0.0:
	set(x):
		screen_offset_min_dist = x
		set_so_diffy()
## How far away from the target does the min offset occur at?
@export var screen_offset_max_dist: float = 50.0:
	set(x):
		screen_offset_max_dist = x
		set_so_diffy()

var scale_diffy: float = 0.0
var screen_offset_diffy: float = 0.0

func _ready() -> void:
	process_priority = 1000
	top_level = true
	set_diffy()
	set_so_diffy()
	set_process(not use_physics_process)
	set_physics_process(use_physics_process)

func set_diffy() -> void:
	scale_diffy = max_dist - min_dist

func set_so_diffy() -> void:
	screen_offset_diffy = screen_offset_max_dist - screen_offset_min_dist

func _process(_delta: float) -> void:
	_update()

func _physics_process(_delta: float) -> void:
	_update()

func _update():
	if (not target) or force_hide:
		visible = false
		return
	if not get_viewport():
		return
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	visible = (target.is_visible_in_tree() or show_through) and camera.is_position_in_frustum(target.global_position)
	if visible:
		var target_position: Vector3 = target.get_global_transform_interpolated().origin
		var cam_dist: float = camera.global_position.distance_to(target_position)
		var scaling_amount := clampf(lerpf(max_scale, min_scale, (cam_dist - min_dist) / scale_diffy), min_scale, max_scale)
		var scaling_amount_so := max_screen_offset.lerp(min_screen_offset, clampf((cam_dist - screen_offset_min_dist) / screen_offset_diffy, 0, 1))
		global_position = camera.unproject_position(target_position) + scaling_amount_so
		scale = Vector2(scaling_amount, scaling_amount)
		
		# z-sorting
		z_index = clampi(-50 - roundi(cam_dist * 10), RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)
