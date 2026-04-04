#@tool
extends Control

const ACHIEVEMENT_SFX := preload('res://audio/sfx/ui/achievement_get.ogg')

## Elements
@onready var origin := $CanvasLayer/Origin
@onready var panel := $CanvasLayer/Origin/PanelMask/Panel
@onready var icon_origin := $CanvasLayer/Origin/IconOrigin
@onready var icon := $CanvasLayer/Origin/IconOrigin/Icon


#@export var test := false:
#	set(x): do_animation()

signal s_animation_finished


func _ready():
	do_animation()

func do_animation() -> void:
	icon_origin.scale = Vector2(0.01, 0.01)
	icon_origin.rotation_degrees = -270.0
	panel.position.x = -500.0
	origin.modulate.a = 1.0
	icon.hide()
	
	var anim_tween := create_tween()
	anim_tween.tween_callback(AudioManager.play_sound.bind(ACHIEVEMENT_SFX))
	anim_tween.set_trans(Tween.TRANS_SPRING)
	anim_tween.set_ease(Tween.EASE_IN)
	anim_tween.tween_property(icon_origin,'scale', Vector2(1.25,1.25), 0.5)
	anim_tween.set_ease(Tween.EASE_OUT)
	anim_tween.parallel().tween_property(icon_origin,'scale', Vector2(1,1), 0.5).set_delay(0.5)
	anim_tween.set_trans(Tween.TRANS_QUAD)
	anim_tween.set_ease(Tween.EASE_IN)
	anim_tween.parallel().tween_property(icon_origin,'rotation_degrees', 45.0, 0.6)
	anim_tween.set_ease(Tween.EASE_OUT)
	anim_tween.parallel().tween_property(icon_origin,'rotation_degrees', 0.0, 0.4).set_delay(0.6)
	anim_tween.set_trans(Tween.TRANS_QUAD)
	anim_tween.parallel().tween_callback(icon.show).set_delay(0.2)
	anim_tween.tween_property(panel,'position:x', 0.0, 0.5)
	anim_tween.tween_interval(5.0)
	anim_tween.set_ease(Tween.EASE_IN)
	anim_tween.tween_property(panel, 'position:x', -500.0, 0.5)
	anim_tween.set_ease(Tween.EASE_IN_OUT)
	anim_tween.parallel().tween_property(icon_origin, 'rotation_degrees', 359.0, 0.6)
	#anim_tween.set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(icon_origin,'scale', Vector2(1.25,1.25), 0.1)
	anim_tween.parallel().tween_property(icon_origin, 'rotation_degrees', 0.0, 0.6)
	anim_tween.parallel().tween_property(icon_origin, 'scale', Vector2(0.001, 0.001), 0.25).set_delay(0.1)
	await anim_tween.finished
	print('animation over')
	anim_tween.kill()
	
	s_animation_finished.emit()
	
	if not Engine.is_editor_hint():
		queue_free()
	
