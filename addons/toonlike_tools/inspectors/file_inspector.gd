@tool
extends EditorInspectorPlugin

const FileProperty = preload('res://addons/toonlike_tools/inspectors/file_property.gd')

func _can_handle(_object: Object) -> bool:
	return true

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags, wide: bool) -> bool:
	if GameLoader.HINT_PREFIX not in hint_string:
		return false
		
	hint_string = hint_string.replace(GameLoader.HINT_PREFIX, '')
	if hint_type == PROPERTY_HINT_FILE:
		var default_property_editor := EditorInspector.instantiate_property_editor(object, type, name, hint_type, hint_string, usage_flags, wide)
		var file_property := FileProperty.new(default_property_editor)
		add_property_editor(name, default_property_editor)
		add_property_editor(name, file_property._preview_editor_property)
		return true
	elif hint_type == PROPERTY_HINT_TYPE_STRING and type == TYPE_PACKED_STRING_ARRAY:
		var default_property_editor := EditorInspector.instantiate_property_editor(object, type, name, hint_type, hint_string, usage_flags, wide)
		var file_property := FileProperty.new(default_property_editor)
		add_property_editor(name, default_property_editor)
		add_property_editor(name, file_property._preview_editor_property)
		return true
	return false
