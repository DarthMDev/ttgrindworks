@tool
extends UIPanel

const COLOR_SUCCESS := Color("00a400")
const COLOR_ERROR := Color("d20000")

func sync_faulty_files(error_paths : Array[String]) -> void:
	for label : Label in %LabelContainer.get_children():
		if label.text.trim_prefix("- ") in error_paths:
			label.text += " (ERROR)"
			label.label_settings.font_color = COLOR_ERROR
		else:
			label.text += " (SUCCESS)"
			label.label_settings.font_color = COLOR_SUCCESS

func open_save_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://save/"))
