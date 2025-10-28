extends Goon
class_name FlyingGoon

@onready var start_y := position.y

var tween: Tween:
	set(x):
		if tween and tween.is_valid():
			tween.kill()
		tween = x

func _ready() -> void:
	super()
	make_loop_tween()
	tween.custom_step(randf_range(0.01, 0.2))

func handle_potential_stomp() -> void:
	make_stomp_tween()

func make_loop_tween() -> void:
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, 'position:y', start_y - 0.3, 2.0)
	tween.tween_property(self, 'position:y', start_y + 0.3, 2.0)
	tween.set_loops()

func make_stomp_tween() -> void:
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, 'position:y', start_y - 0.45, 0.5)
	tween.tween_property(self, 'position:y', start_y, 0.7)
	tween.tween_callback(make_loop_tween)
	tween.set_loops()
