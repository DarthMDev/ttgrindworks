extends MeshInstance3D

const DOWN_Y := -5.9

func on_button_press(_button) -> void:
	var down_tween := create_tween().set_trans(Tween.TRANS_QUAD)
	down_tween.tween_property(self, 'position:y', DOWN_Y, 2.0)
