@tool
extends StaticBody3D

enum TextureType { REGULAR, HOT }

const EDGE_REGULAR_MAT := preload("res://objects/obstacles/sinking_platform/edge_regular_mat.tres")
const EDGE_HOT_MAT := preload("res://objects/obstacles/sinking_platform/edge_hot_mat.tres")
const TOP_REGULAR_MAT := preload("res://objects/obstacles/sinking_platform/top_regular_mat.tres")
const TOP_HOT_MAT := preload("res://objects/obstacles/sinking_platform/top_hot_mat.tres")

@export var texture_type := TextureType.REGULAR:
	set(x):
		texture_type = x
		await NodeGlobals.until_ready(self)
		update_textures()

var sinking: bool:
	get:
		if is_instance_valid(Util.get_player()):
			return player_on_platform and Util.get_player().state != Player.PlayerState.STOPPED
		return false
var player_on_platform := false
@onready var platform := $Platform
@export var sink_level := -1.0
@export var sink_speed := 0.5
@onready var surface_level := position.y
@onready var platform_mesh: MeshInstance3D = get_node("Platform/platform2/platform")

func body_entered(body : Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body is Player:
		return
	player_on_platform = true

func body_exited(body : Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body is Player:
		return
	player_on_platform = false

func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if sinking and position.y > sink_level:
		position.y -= delta * sink_speed
	elif not sinking and position.y < surface_level:
		position.y += delta * sink_speed

func update_textures() -> void:
	platform_mesh.set_surface_override_material(0, EDGE_HOT_MAT if texture_type == TextureType.HOT else EDGE_REGULAR_MAT)
	platform_mesh.set_surface_override_material(1, TOP_HOT_MAT if texture_type == TextureType.HOT else TOP_REGULAR_MAT)
