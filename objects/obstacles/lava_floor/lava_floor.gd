extends Area3D
class_name LavaFloor


enum LavaType {
	DAMAGE_TICK,
	TELEPORT
}

signal s_lava_hit

@export var tick_delay := 2.0
@export var base_damage := -1
@export var damage_name: String = "Molten Lava"
@export var lava_type := LavaType.TELEPORT
@export var checkpoints : Dictionary[Area3D, Node3D] = {}
@export var default_spawn_point : Node3D

var active := true
var timer: Timer
var hp_tick := -1
var current_checkpoint : Node3D


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = tick_delay
	timer.one_shot = true
	
	hp_tick = Util.get_hazard_damage() + base_damage
	
	
	# Set up teleportation
	if default_spawn_point:
		current_checkpoint = default_spawn_point

	if checkpoints.is_empty() and lava_type == LavaType.TELEPORT and not current_checkpoint:
		push_warning("LavaFloor: Checkpoint dictionary is empty. Assigning self as respawn point.")
		current_checkpoint = self

	for checkpoint in checkpoints:
		checkpoint.set_collision_mask_value(Globals.PLAYER_COLLISION_LAYER, true)
		checkpoint.body_entered.connect(checkpoint_check.bind(checkpoint))


func body_entered(body : Node3D) -> void:
	if not body is Player or not active:
		return
	while overlaps_body(Util.get_player()):
		active = false
		hurt_player()
		timer.start()
		await timer.timeout
		active = true

func hurt_player() -> void:
	s_lava_hit.emit()
	var player := Util.get_player()
	if player.is_invincible():
		return
	if lava_type == LavaType.TELEPORT:
		reset_to_checkpoint(player)
	player.last_damage_source = damage_name
	player.quick_heal(hp_tick)
	if player.toon.yelp:
		AudioManager.play_sound(player.toon.yelp)

func check_for_player():
	if overlaps_body(Util.get_player()):
		hurt_player()

func reset_to_checkpoint(player : Player) -> void:
	Util.circle_in(1.0)
	
	player.global_position = current_checkpoint.global_position
	player.reset_physics_interpolation()
	await player.teleport_in(true)
	if player.stats.hp <= 0:
		player.lose()

func checkpoint_check(body : Node3D, checkpoint : Area3D) -> void:
	if body is Player:
		current_checkpoint = checkpoints[checkpoint]
