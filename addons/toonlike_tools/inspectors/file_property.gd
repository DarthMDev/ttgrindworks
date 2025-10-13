@tool
extends HBoxContainer

var _preview_button: Button

var _default_editor_property: EditorProperty
var _default_editor_control: Control
var _preview_editor_property: EditorProperty

var preview_on_icon := EditorInterface.get_base_control().get_theme_icon(
	'ZoomMore', 'EditorIcons'
)
var preview_off_icon := EditorInterface.get_base_control().get_theme_icon(
	'ZoomLess', 'EditorIcons'
)

class Preview:
	var preview
	
var preview: Preview

func _init(default_editor_property: EditorProperty):
	_default_editor_property = default_editor_property
	_default_editor_control = _default_editor_property.get_child(0)
	_default_editor_control.reparent(self)
	_default_editor_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_editor_property.add_child(self)

	_preview_button = Button.new()
	_preview_button.toggle_mode = true
	_preview_button.icon = preview_on_icon
	add_child(_preview_button)
	preview = Preview.new()
	_preview_editor_property = EditorProperty.new()
	
	_preview_button.toggled.connect(_toggle_preview)
	_default_editor_property.property_changed.connect(_on_property_changed)

func _ready():
	_toggle_preview(false)
	_preview_button.disabled = not _can_preview()

func _can_preview() -> bool:
	var paths := _get_paths()
	return paths and paths.any(func(path): return ResourceLoader.exists(path))

func _get_paths() -> Array[String]:
	var object := _default_editor_property.get_edited_object()
	var value := object.get(_default_editor_property.get_edited_property())
	var array: Array[String]
	if not value:
		array.assign([])
	elif typeof(value) == TYPE_STRING:
		array.assign([str(value)])
	else:
		array.assign(Array(value))
	return array

func _load_preview():
	if preview.preview:
		return
	
	var object := _default_editor_property.get_edited_object()
	var path := object.get(_default_editor_property.get_edited_property())
	if not path:
		return
	
	if typeof(path) == TYPE_STRING:
		preview.preview = load(path)
	else:
		preview.preview = Array(path).map(func(x): return load(x))

	var preview_editor_property := EditorInspector.instantiate_property_editor(
		preview, typeof(preview.preview), "preview", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NONE
	)
	preview_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_editor_property.name_split_ratio = 0.5
	preview_editor_property.read_only = true
	
	preview_editor_property.property_changed.connect(_on_property_changed)
	preview_editor_property.set_object_and_property(preview, "preview")
	preview_editor_property.update_property()
	_preview_editor_property.replace_by(preview_editor_property)
	_preview_editor_property = preview_editor_property

func _toggle_preview(toggled_on: bool):
	if toggled_on:
		_load_preview()
		if not preview.preview:
			_preview_button.set_pressed_no_signal(false)
			return
		
		_preview_editor_property.show()
		_preview_button.icon = preview_off_icon
	else:
		_preview_editor_property.hide()
		_preview_button.icon = preview_on_icon

func _on_property_changed(property: StringName, value: Variant, _field: StringName, _changing: bool):
	if property == 'preview':
		preview.preview = value
		_preview_editor_property.update_property()
	else:
		_preview_button.disabled = not _can_preview()
