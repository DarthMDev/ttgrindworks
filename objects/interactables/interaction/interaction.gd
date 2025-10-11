extends Area3D
class_name Interaction


@export var interaction_camera: Camera3D
@export var one_shot := false
@export var can_interact := true

var player: Player

signal s_interacted
signal s_player_interacted(player: Player)
signal s_interaction_finished
signal s_interaction_finished_player(player: Player)


## OVERRIDE THIS THING
func interact() -> void:
	stop_player()
	do_camera_transition()
	await Task.delay(1.0)
	player.set_animation('jump')
	await player.toon.legs.animator.animation_finished
	unstop_player()
	s_interaction_finished.emit()
	s_interaction_finished_player.emit(player)

func do_camera_transition(to: Camera3D = interaction_camera, time := 1.0) -> void:
	CameraTransition.from_current(self, to, time)

func stop_player() -> void:
	player.state = player.PlayerState.STOPPED
	player.set_animation('neutral')
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unstop_player() -> void:
	player.state = player.PlayerState.WALK

func _ready() -> void:
	body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D) -> void:
	if not can_interact:
		return
	
	if body is Player:
		player = body
		interact()
		s_interacted.emit()
		s_player_interacted.emit(player)
		if one_shot:
			can_interact = false

func _standard_exit() -> void:
	do_camera_transition(player.camera.camera)
	await Task.delay(1.0)
	unstop_player()
