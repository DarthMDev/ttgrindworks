@tool
extends Node3D


const ANIMATION_BUFFER_RANGE := Vector2(4.0, 10.0)

@export var scope_meshes: Array[MeshInstance3D] = []
@export var animator: AnimationPlayer
@export var sfx_emerge: AudioSnippetPlayer3D
@export var sfx_recede: AudioSnippetPlayer3D

@export var show_scopes: bool = true:
	get:
		if scope_meshes.is_empty(): return false
		return scope_meshes[0].visible
	set(x):
		set_scopes_visible(x)

@onready var crank_sfx: Array[AudioStreamPlayer3D] = [
	%SFXCrankHigh,
	%SFXCrankNorm,
	%SFXCrankLow,
]

var disable_rustle := false


func set_scopes_visible(toggle: bool) -> void:
	for mesh in scope_meshes: mesh.set_visible(toggle)
	if not toggle:
		rustle_restart()

func set_animation(anim: String) -> void:
	if animator.has_animation(anim):
		animator.play(anim)
	else:
		printerr("ERR: No animation: %s in Stranger's AnimationPlayer" % anim)

func rustle() -> void:
	if show_scopes: return
	
	# Play a rustle anim
	var rustle_anims: Array[String] = ['in-idle1', 'in-idle2', 'in-idle3']
	if not disable_rustle:
		set_animation(rustle_anims.pick_random())
	
	rustle_restart()

func rustle_restart() -> void:
	# Reset our timer
	await NodeGlobals.until_ready(%AnimationTimer)
	%AnimationTimer.set_wait_time(randf_range(ANIMATION_BUFFER_RANGE.x, ANIMATION_BUFFER_RANGE.y))
	%AnimationTimer.start()

func scopes_emerge() -> void:
	set_animation('intro')
	set_scopes_visible(true)
	if animator.animation_finished.is_connected(on_recede_finish):
		animator.animation_finished.disconnect(on_recede_finish)

func scopes_recede() -> void:
	animator.play_backwards('intro')
	animator.animation_finished.connect(on_recede_finish, CONNECT_ONE_SHOT)
	for sfx in crank_sfx:
		sfx.stop()

func on_recede_finish(_anim) -> void:
	set_scopes_visible(false)

func play_emerging_sound() -> void:
	if not is_equal_approx(animator.get_playing_speed(), -1.0):
		if is_instance_valid(sfx_emerge): sfx_emerge.play()
	elif is_instance_valid(sfx_recede): sfx_recede.play()
