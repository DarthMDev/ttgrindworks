@tool
extends AnimatableBody3D

@export var path: Path3D:
	set(x):
		if is_instance_valid(path):
			path.queue_free()
		path = x
		update_path()
		if x:
			x.curve_changed.connect(update_path)
@export var speed := 1.0

var follower: PathFollow3D
var tween: Tween

func update_path() -> void:
	if not path:
		return
	
	follower = PathFollow3D.new()
	follower.loop = true
	path.add_child(follower)
	reset_tween(path.curve)

func reset_tween(curve: Curve3D) -> void:
	if tween: tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	for i in curve.get_point_count():
		tween.tween_property(self, ^"position", curve.get_point_position(i), speed)
	tween.set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE and path and path.curve and path.curve.get_point_count() > 0:
		# Before save, place at last point so that it will immediately move to the first in practice
		position = path.curve.get_point_position(path.curve.get_point_count() - 1)
