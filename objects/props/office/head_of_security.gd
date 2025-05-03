@tool
extends Node3D

@export var shake_intensity : float = 1.0:
	set(x):
		shake_intensity = x
		if not is_node_ready():
			await ready
		set_glitch_intensity(shake_intensity)

@onready var head_mod : MeshInstance3D = %Cube
@onready var glitch_timer : Timer = %GlitchTimer

var FONT : Font
var SPEECH_BUBBLE : PackedScene
var speech_bubble : SpeechBubble
var speak_sfx : AudioStream

func _init() -> void:
	if Engine.is_editor_hint(): return
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self,
	{
		'SPEECH_BUBBLE' : "res://objects/misc/speech_bubble/speech_bubble.tscn",
		'FONT' : "res://fonts/vtRemingtonPortable.ttf",
		'speak_sfx' : "res://audio/sfx/battle/cogs/Skel_COG_VO_statement.ogg",
	})

@onready var animator : AnimationPlayer = %AnimationPlayer

func set_animation(anim : String) -> void:
	animator.play(anim)

func speak(phrase : String) -> void:
	if is_instance_valid(speech_bubble):
		speech_bubble.queue_free()
	speech_bubble = SPEECH_BUBBLE.instantiate()
	%SpeechNode.add_child(speech_bubble)
	speech_bubble.target = %SpeechNode
	speech_bubble.set_font(FONT)
	speech_bubble.set_text(phrase)
	AudioManager.play_sound(speak_sfx)

func _ready() -> void:
	glitch_timer.start()

const RATE_VARIANCE := Vector2(1.0, 2.0)
var GLITCH_TIME := 0.1
func timer_timeout() -> void:
	toggle_glitch()
	
	
	if glitch_enabled:
		glitch_timer.wait_time = GLITCH_TIME
	elif Engine.is_editor_hint():
		glitch_timer.wait_time = randf_range(RATE_VARIANCE.x, RATE_VARIANCE.y)
	else:
		glitch_timer.wait_time = RandomService.randf_range_channel('true_random', RATE_VARIANCE.x, RATE_VARIANCE.y)
	glitch_timer.start()

var glitch_enabled := true
func toggle_glitch() -> void:
	glitch_enabled = not glitch_enabled
	var shader : ShaderMaterial = head_mod.get_surface_override_material(0)
	shader.set_shader_parameter('should_shake', glitch_enabled)

func set_glitch_intensity(intensity : float) -> void:
	var shader : ShaderMaterial = head_mod.get_surface_override_material(0)
	shader.set_shader_parameter('shake_power', intensity)

func do_explosion() -> void:
	if Engine.is_editor_hint(): return
	
	var explosion : AnimatedSprite3D = Globals.EXPLOSION.instantiate()
	add_child(explosion)
	explosion.scale *= 20.0
	explosion.play()
	AudioManager.play_sound(GameLoader.load('res://audio/sfx/battle/cogs/ENC_cogfall_apart.ogg'))
	await Task.delay(0.1)
	head_mod.hide()
	await Task.delay(0.45)
	queue_free()
	

func _process(_delta : float) -> void:
	pass
	#%SpeechNode.global_position.y = %SpeechPos.global_position.y
