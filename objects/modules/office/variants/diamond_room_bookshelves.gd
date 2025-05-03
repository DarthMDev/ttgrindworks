extends Node3D

@export var move_pos := Vector3(-18.76, 0, 10.302)

var buttons_pressed := 0
var seq: Tween:
	set(x):
		if seq and seq.is_valid():
			seq.kill()
		seq = x
		

func move_bookshelves() -> void:
	seq = Sequence.new([
		LerpProperty.new(self, ^"position", 2.0, move_pos).interp(Tween.EASE_IN_OUT, Tween.TRANS_QUAD)
	]).as_tween(self)


func button_pressed(button: CogButton) -> void:
	buttons_pressed += 1
	if buttons_pressed == 2:
		move_bookshelves()
