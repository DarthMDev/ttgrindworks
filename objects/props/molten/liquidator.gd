extends Node3D

const FIREBALL := preload("res://objects/modules/molten/variants/chase_boss/liquidator_fireball.tscn")

@onready var animator: AnimationPlayer = %AnimationPlayer
@onready var collider: Area3D = %CollisionDetection
@onready var sfx_player: AudioStreamPlayer = %DialSFX

signal s_player_collided(player: Player)

const SFX_ROAR := "res://audio/sfx/objects/liquidator/liquidator_roar.ogg"

var neutral_anim := &'Idle'

func set_animation(anim: String) -> void:
	if animator.has_animation(anim):
		animator.play(anim)

func body_entered(body: Node3D) -> void:
	if body is Player:
		s_player_collided.emit(body)
	if body is StaticBody3D:
		if body.get_parent() is CrumblingPlatform:
			body.get_parent().crumble()

func player_entered(_player: Player) -> void:
	pass

func roar(hear_the_roar := true) -> void:
	set_animation('Roar')
	if hear_the_roar:
		play_roar_sound()

func play_roar_sound() -> void:
	play_dial_sound(load(SFX_ROAR))

func play_dial_sound(sfx: AudioStream) -> void:
	sfx_player.set_stream(sfx)
	sfx_player.play()

func spit() -> Area3D:
	if not can_do_action(): return
	var fireball := FIREBALL.instantiate()
	set_animation('Spitball_Walk')
	await Task.delay(0.45)
	if not animator.current_animation == 'Spitball_Walk': return
	play_dial_sound(load('res://audio/sfx/objects/liquidator/liquidator_spit.ogg'))
	await Task.delay(0.2)
	if not animator.current_animation == 'Spitball_Walk': return
	SceneLoader.current_scene.add_child(fireball)
	fireball.global_position = %FireballOrigin.global_position
	return fireball

const NEUTRAL_ANIMS: Array[StringName] = [
	&'Idle',
	&'Walk',
]

func can_do_action() -> bool:
	if not animator.current_animation in NEUTRAL_ANIMS:
		return false
	return true

func on_anim_finished(_anim: StringName) -> void:
	set_animation(neutral_anim)
