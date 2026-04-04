extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	%FakeMouse.visible = Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN
	%FakeMouse.global_position = %FakeMouse.get_global_mouse_position()
