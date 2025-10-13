extends ColorRect
class_name CircleTransition


func _ready() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	size = Vector2(viewport_size.x,viewport_size.x)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE)

func open(time := 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(set_circle_size,0.0,1.0,time)
	await tween.finished
	tween.kill()
	queue_free()

func close(time := 1.0) -> void:
	set_circle_size(1.0)
	var tween := create_tween()
	tween.tween_method(set_circle_size,1.0,0.0,time)
	await tween.finished
	tween.kill()
	queue_free()

func set_circle_size(circle_size : float) -> void:
	material.set_shader_parameter('circle_size',circle_size)
