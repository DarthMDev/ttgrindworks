@tool
extends Control


const POS_OUT := 680.0
const POS_IN := 600.0
const SCALE_UP := Vector2(1.2, 1.2)
const SCALE_DOWN := Vector2(1.0, 1.0)
const ROTATION_DEG := 5.0

@export_tool_button('pop in') var pop = pop_in

var pop_tween: Tween
var blunders := 0


func _ready() -> void:
	Globals.s_im_stuck.connect(pop_in)

func pop_in() -> void:
	if pop_tween and pop_tween.is_running():
		pop_tween.kill()
	%LabelOrigin.position.y = POS_OUT
	%LabelScaler.scale = SCALE_DOWN
	pop_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	pop_tween.tween_property(%LabelOrigin, 'position:y', POS_IN, 0.2)
	pop_tween.tween_callback(%SFXDing.play)
	pop_tween.tween_callback(increment)
	pop_tween.tween_property(%LabelScaler, 'scale', SCALE_UP, 0.3)
	pop_tween.parallel().tween_property(%LabelScaler, 'rotation_degrees', ROTATION_DEG, 0.5)
	pop_tween.tween_property(%LabelScaler, 'scale', SCALE_DOWN, 0.3)
	pop_tween.parallel().tween_property(%LabelScaler, 'rotation_degrees', -(ROTATION_DEG / 2.0), 0.5)
	pop_tween.tween_property(%LabelOrigin, 'position:y', POS_OUT, 0.2)
	pop_tween.parallel().tween_property(%LabelScaler, 'rotation_degrees', 0.0, 0.5)
	pop_tween.finished.connect(pop_tween.kill)

func increment() -> void:
	blunders += 1
	%Label.text = "Collision Blunders: %d" % blunders

func on_im_stuck() -> void:
	pop_in()
