extends Control


func _ready() -> void:
	AudioManager.stop_music(true)
	Util.get_player().queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	%ConnectingPanel.show()
	await Task.delay(5.0)
	%ConnectingPanel.hide()
	%BrokenPanel.show()


func ok() -> void:
	get_tree().quit()
