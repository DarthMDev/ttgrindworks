extends Panel
class_name FileDisplayer

const SELECTED_ALPHA := 0.25
const MAX_STRING_LENGTH := 12

@export var file : UIFile

@onready var icon_rect : TextureRect = $Elements/Icon
@onready var filename_label : Label = $Elements/FileName
@onready var model_viewer : TextureRect = $Elements/ModelView

var file_name : String:
	get:
		if filename_label: return filename_label.get_text()
		return ""

signal s_selected
signal s_deselected
signal s_right_clicked


func set_file(new_file : UIFile) -> void:
	file = new_file
	refresh()

func refresh() -> void:
	icon_rect.set_texture(file.icon)
	filename_label.set_text(get_file_name(file.file_path))
	if file.model:
		model_viewer.node = file.model
		model_viewer.show()
		icon_rect.hide()

func get_file_name(file_path : String) -> String:
	var split_path := file_path.split("/")
	var return_string := split_path[split_path.size() - 1]
	return_string = return_string.trim_suffix(".%s" % return_string.get_extension())
	if return_string.length() > MAX_STRING_LENGTH:
		return_string = return_string.left(MAX_STRING_LENGTH) + "..."
	return return_string

func on_focus_entered() -> void:
	self_modulate.a = SELECTED_ALPHA
	s_selected.emit()

func on_focus_exited() -> void:
	self_modulate.a = 0.0
	s_deselected.emit()

func on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			s_right_clicked.emit()
