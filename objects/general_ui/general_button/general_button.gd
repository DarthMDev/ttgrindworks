@tool
extends TextureButton
class_name GeneralButton

@export var press_sfx: AudioStream
@export var hover_sfx: AudioStream
@export var hover_db_offset := 6.0
@export var press_db_offset := 0.0
@export_multiline var text := "":
	set(x):
		$Label.text = x
	get:
		return $Label.text
@export var font_size: float:
	set(x):
		$Label.label_settings.font_size = x
	get:
		return $Label.label_settings.font_size

func on_button_down() -> void:
	if press_sfx:
		AudioManager.play_sound(press_sfx, press_db_offset)

func on_mouse_entered() -> void:
	if hover_sfx:
		AudioManager.play_sound(hover_sfx, hover_db_offset)
