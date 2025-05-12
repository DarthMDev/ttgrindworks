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

@onready var collision_shape : BoxShape3D = %CollisionShape3D.shape

func _ready() -> void:
	initialize()

func update_size() -> void:
	mesh.size = size
	mesh.material.set_shader_parameter('uv_scale', size / SCALE_FACTOR)
	collision_shape.size.x = size.x * AREA_SIZE
	collision_shape.size.z = size.y * AREA_SIZE



#region PLAYER DETECTION
const SPEED_PENALTY := -0.5

var stat_mult : StatMultiplier

func initialize() -> void:
	stat_mult = StatMultiplier.new()
	stat_mult.stat = 'speed'
	stat_mult.additive = true
	stat_mult.amount = SPEED_PENALTY

func body_entered(body : Node3D) -> void:
	if body is Player:
		player_entered(body)

func body_exited(body : Node3D) -> void:
	if body is Player:
		player_exited(body)

func player_entered(player : Player) -> void:
	player.stats.multipliers.append(stat_mult)
	player.can_sprint = false
	player.can_jump = false

func player_exited(player : Player) -> void:
	player.stats.multipliers.erase(stat_mult)
	player.can_sprint = true
	player.can_jump = true

#endregion
