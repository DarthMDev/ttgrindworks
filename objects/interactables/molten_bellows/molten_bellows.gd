@tool
extends Node3D
class_name MoltenBellows

const UNIT_SIZE := 18.4
const BASE_SPRING_SIZE := 100.0
const MINIMUM_RETRACT := -5.0
const VOLUME_RANGE := Vector2(0.0, 20.0)
const PITCH_RANGE := Vector2(0.75, 1.75)
const BASE_RETRACT := 0.0

@export var retract_amount := BASE_RETRACT:
	set(x):
		retract_amount = maxf(x, MINIMUM_RETRACT)
		await NodeGlobals.until_ready(self)
		update_retract()
@export var retract_speed := 8.0
@export var push_force := 1.0
@export var min_push := 1.0
@export var max_push := 3.0

var stack_link_above: MoltenBellows:
	set(new):
		platform_animatable_body.sync_to_physics = false
		player_detection.monitoring = false
		stack_link_above = new
		set_entry_particles_enabled(true)
		retracting = true
	
@export var stack_link_below: MoltenBellows:
	set(new):
		if stack_link_below:
			stack_link_below.stack_link_above = null
		stack_link_below = new
var stack_link_tween: Tween

@onready var base: MeshInstance3D = %Base
@onready var platform: MeshInstance3D = %Platform
@onready var platform_animatable_body: AnimatableBody3D = %Platform/AnimatableBody3D
@onready var spring: MeshInstance3D = %Spring
@onready var player_detection: Area3D = %PlayerDetection
@onready var disable_timer: Timer = %DisableTimer
@onready var animator: AnimationPlayer = %AnimationPlayer
@onready var entry_particles: Array[GPUParticles3D] = [
	%SteamEntry, %SteamEntry2, %SteamEntry3, %SteamEntry4
]

var bounce_tween: Tween
var retracting := false


func update_retract() -> void:
	spring.scale.z = BASE_SPRING_SIZE + (UNIT_SIZE * retract_amount)

func body_entered(body: Node3D) -> void:
	if body is Player:
		player_entered(body)

func player_entered(player: Player) -> void:
	if stack_link_above:
		return
	player.s_jumped.connect(on_player_jumped.bind(player), CONNECT_ONE_SHOT)
	set_entry_particles_enabled(true)
	retracting = true

func body_exited(body: Node3D) -> void:
	if body is Player:
		player_exited(body)
		set_entry_particles_enabled(false)

func player_exited(player: Player) -> void:
	if stack_link_above:
		return
	if player.s_jumped.is_connected(on_player_jumped):
		player.s_jumped.disconnect(on_player_jumped)
	if stack_link_below:
		do_stacked_bounceback()
	else:
		do_bounceback()
		retracting = false
		do_particles_exit()

func on_player_jumped(player: Player) -> void:
	var stacked_max_push := max_push
	var num_of_jumps := 1
	var current_bellows := stack_link_below
	while current_bellows:
		num_of_jumps += 1
		stacked_max_push += current_bellows.max_push * (1.0 / num_of_jumps)
		current_bellows = current_bellows.stack_link_below
	var jump_mult := clampf(get_jump_mult() * num_of_jumps, min_push, stacked_max_push)
	player.velocity.y *= jump_mult
	player_exited(player)

func do_stacked_bounceback() -> void:
	var tween := get_tree().create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_callback(func():
		do_bounceback()
		retracting = false
		do_particles_exit()
		#%PlayerDetection.monitoring = false
	)
	
	if stack_link_below:
		stack_link_below.do_stacked_bounceback()
		#tween.set_ease(Tween.EASE_OUT)
		#tween.tween_property(self, "position", Vector3(0, 0, 2.0), 0.5)
		#tween.tween_callback(%PlayerDetection.set_monitoring.bind(true))
		#tween.set_ease(Tween.EASE_IN)
		#tween.tween_property(self, "position", Vector3(0, 0, 0), 0.5)
		
	if stack_link_above:
		tween.tween_callback(func():
			retracting = true
			set_entry_particles_enabled(true)
		)

func do_bounceback() -> void:
	if bounce_tween and bounce_tween.is_running():
		return
	bounce_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	bounce_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	bounce_tween.set_parallel(true)
	bounce_tween.tween_property(self, 'retract_amount', BASE_RETRACT, 0.4)
	bounce_tween.finished.connect(bounce_tween.kill)
	%BoingySproings.pitch_scale = PITCH_RANGE.y - ((PITCH_RANGE.y - PITCH_RANGE.x) * get_retract_perc())
	%BoingySproings.volume_db = VOLUME_RANGE.x + ((VOLUME_RANGE.y - VOLUME_RANGE.x) * get_retract_perc())
	%BoingySproings.play()

func get_retract_perc() -> float:
	return absf(retract_amount / MINIMUM_RETRACT)

func do_temp_disable() -> void:
	player_detection.set_deferred('monitoring', false)
	disable_timer.start()

func disable_timeout() -> void:
	player_detection.set_deferred('monitoring', true)

func _physics_process(delta: float) -> void:
	if retracting:
		retract_amount -= delta * retract_speed
		if retract_amount <= MINIMUM_RETRACT:
			set_entry_particles_enabled(false)

func get_jump_mult() -> float:
	var ratio := absf(retract_amount / MINIMUM_RETRACT)
	return maxf(ratio * max_push, min_push)

func set_entry_particles_enabled(enable: bool) -> void:
	if enable:
		animator.play('steam_inhale')
		%Steam.show()
		%AirIntake.play()
	else:
		for particle in entry_particles:
			particle.set_emitting(false)
			%Steam.hide()
			%AirIntake.stop()
			

func do_particles_exit() -> void:
	animator.play('steam_exhale')

func move_to_stack_link_below():
	if not stack_link_below:
		return
	
	self.reparent(stack_link_below.platform)
	self.platform_animatable_body.sync_to_physics = false
	var tween := get_tree().create_tween()
	if not is_zero_approx(position.x) or not is_zero_approx(position.y):
		tween.set_trans(Tween.TRANS_EXPO)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", Vector3(0, 0, position.z), 1.0)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector3(0, 0, 0), 2)
	tween.tween_callback(func(): 
		stack_link_below.stack_link_above = self
		self.platform_animatable_body.sync_to_physics = true
	)

func get_stack_count() -> int:
	var bellows_count := 0
	var current_bellows := self
	while current_bellows:
		bellows_count += 1
		current_bellows = current_bellows.stack_link_below
	return bellows_count
