extends Node3D
class_name Elevator

## Config
@export var animator: AnimationPlayer
@export var player_pos: Node3D
@export var elevator_cam: Camera3D
@export var scene_path: String
@export var monitoring := true
@export var opened := false
@export var connect_to_game_floor := true

signal s_elevator_entered


func _ready() -> void:
	if opened and animator:
		animator.play('RESET_OPEN')
	
	# Send floor ended signal when entered
	if connect_to_game_floor and is_instance_valid(Util.floor_manager):
		s_elevator_entered.connect(func(): Util.floor_manager.s_floor_ended.emit())

func body_entered(body : Node3D) -> void:
	if body is Player and monitoring:
		monitoring = false
		player_entered(body)

func player_entered(player : Player) -> void:
	player.game_timer_tick = false
	elevator_cam.make_current()
	player.state = Player.PlayerState.STOPPED
	s_elevator_entered.emit()
	
	player.set_animation('run')
	var move_tween := player.move_to(player_pos.global_position)
	await move_tween.finished
	move_tween.kill()
	
	# Apparently setting the toon's global rotation resets scale
	# So that's kinda dumb
	var toon_scale = player.toon.scale
	player.toon.global_rotation.y = player_pos.global_rotation.y
	player.toon.scale = toon_scale
	
	close()
	await animator.animation_finished
	await get_tree().create_timer(1.0).timeout
	SceneLoader.load_into_scene(scene_path)


func open() -> void:
	AudioManager.play_sound(load('res://audio/sfx/objects/elevator/elevator_door_open.ogg'))
	animator.play('open')

func close() -> void:
	AudioManager.play_sound(load('res://audio/sfx/objects/elevator/elevator_door_close.ogg'))
	animator.play('close')

func set_monitoring(monitor : bool) -> void:
	monitoring = monitor
