@tool
extends MeshInstance3D
class_name ObstacleSandTrap

const SCALE_FACTOR := Vector2(2.395, 2.358)
const AREA_SIZE := 0.8

@export var size := Vector2.ONE:
	set(x):
		size = x
		if not is_node_ready():
			await ready
		update_size()

@onready var collision_shape: BoxShape3D = %CollisionShape3D.shape

func update_size() -> void:
	mesh.size = size
	mesh.material.set_shader_parameter('uv_scale', size / SCALE_FACTOR)
	collision_shape.size.x = size.x * AREA_SIZE
	collision_shape.size.z = size.y * AREA_SIZE

#region PLAYER DETECTION

func body_entered(body: Node3D) -> void:
	if body is Player:
		player_entered(body)

func body_exited(body: Node3D) -> void:
	if body is Player:
		player_exited(body)

func player_entered(player: Player) -> void:
	player.controller.current_state.can_jump = false

func player_exited(player: Player) -> void:
	player.controller.current_state.can_jump = true

#endregion
