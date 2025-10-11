@tool
extends EditorPlugin
class_name SceneLockEditorPlugin

class SceneInspector extends EditorInspectorPlugin:
	var lock_message: CenterContainer
	var property_editors := []
	var grabbing_default := false
	
	func _init():
		var container := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.texture = EditorInterface.get_base_control().get_theme_icon(
			'Lock', 'EditorIcons'
		)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		container.add_child(icon)
		var label := Label.new()
		label.text = 'This scene is locked to prevent accidental modification.\n\
			You can unlock it at the top of the inspector.'
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)
		
		lock_message = CenterContainer.new()
		lock_message.add_child(container)
	
	func _can_handle(object: Object):
		var scene_root: Node = null
		if object is Node:
			if object.owner:
				scene_root = object.owner
			elif object.scene_file_path:
				scene_root = object
		return scene_root and scene_root.has_meta("_locked") and not SceneLockEditorPlugin._is_inherited_scene(scene_root)
	
	func _parse_begin(object: Object):
		add_custom_control(lock_message.duplicate(0))
	
	func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
		if grabbing_default:
			return false
		else:
			var default_property_editor := _get_inspector(object, type, name, hint_type, hint_string, usage_flags, wide)
			property_editors.append(default_property_editor)
			add_property_editor(name, default_property_editor)
			return true
			
	func _parse_end(object: Object):
		for editor in property_editors:
			editor.read_only = true
			editor.update_property()
		property_editors.clear()
		
	func _get_inspector(object: Object, type: Variant.Type, path: String, hint: PropertyHint, hint_text: String, usage: int, wide: bool) -> EditorProperty:
		grabbing_default = true
		var default_property_editor := EditorInterface.get_inspector().instantiate_property_editor(object, type, path, hint, hint_text, usage, wide)
		grabbing_default = false
		return default_property_editor


var scene_inspector := SceneInspector.new()
var lock_button: Button

var lock_icon := EditorInterface.get_base_control().get_theme_icon(
	'Lock', 'EditorIcons'
)
var unlock_icon := EditorInterface.get_base_control().get_theme_icon(
	'Unlock', 'EditorIcons'
)

const LOCK_TOOLTIP := 'Lock the current scene to prevent accidental edits.'
const UNLOCK_TOOLTIP := 'Unlock the current scene to edit it.'

const CONFIRMATION_TEXT := "This scene was locked to prevent accidental edits from being saved to an important scene.\n\
	If you're testing something, try creating an inherited scene instead.\n\nUnlock the scene?"
const CONFIRMATION_ALT_TEXT := "This scene was locked to prevent accidental edits from being saved to an important scene.\n\
	An inherited scene exists for testing: %s\n\nUnlock the scene?"

func _create_lock_button() -> Button:
	var lock_button := Button.new()
	lock_button.toggle_mode = true
	lock_button.icon = unlock_icon
	lock_button.tooltip_text = LOCK_TOOLTIP
	lock_button.theme_type_variation = 'FlatMenuButton'
	lock_button.toggled.connect(_toggle_lock)
	return lock_button
	
func _create_confirmation_dialog(scene_root: Node) -> ConfirmationDialog:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = CONFIRMATION_TEXT
	dialog.ok_button_text = 'Unlock'
	dialog.canceled.connect(func():
		_toggle_lock(true)
		dialog.queue_free()
	)
	dialog.confirmed.connect(dialog.queue_free)
	
	var alt_scene := scene_root.get_meta("_locked_alt_scene", "")
	if alt_scene:
		dialog.dialog_text = CONFIRMATION_ALT_TEXT % alt_scene
		var open_button := dialog.add_button("Open Inherited Scene", false, "open_inherited")
		open_button.grab_focus.call_deferred()
		dialog.custom_action.connect(func(_action):
			_toggle_lock(true)
			dialog.queue_free()
			EditorInterface.open_scene_from_path(alt_scene)
		)
	return dialog

static func _get_edited_scene_root() -> Node:
	var object := EditorInterface.get_inspector().get_edited_object()
	if object is Node:
		if object.owner:
			return object.owner
		elif object.scene_file_path:
			return object
	return null

static func _is_inherited_scene(scene_root: Node) -> bool:
	if scene_root.scene_file_path:
		var packed_scene: PackedScene = load(scene_root.scene_file_path)
		if packed_scene:
			return packed_scene.get_state().get_node_instance(0) != null
	return false

func _toggle_lock(toggled_on: bool):
	var scene_root := _get_edited_scene_root()
	if not scene_root:
		return
	
	if toggled_on:
		scene_root.set_meta("_locked", true)
	else:
		var dialog := _create_confirmation_dialog(scene_root)
		EditorInterface.popup_dialog_centered(dialog)
		scene_root.remove_meta("_locked")
		await dialog.visibility_changed
	_update_lock()
	EditorInterface.get_inspector().edit(null)
	EditorInterface.get_inspector().edit(scene_root)

func _update_lock():
	if not lock_button:
		return
	
	var scene_root := _get_edited_scene_root()
	
	if scene_root and not _is_inherited_scene(scene_root):
		if scene_root.has_meta("_locked"):
			lock_button.set_pressed_no_signal(true)
			lock_button.icon = lock_icon
			lock_button.tooltip_text = UNLOCK_TOOLTIP
		else:
			lock_button.set_pressed_no_signal(false)
			lock_button.icon = unlock_icon
			lock_button.tooltip_text = LOCK_TOOLTIP
		lock_button.disabled = false
	else:
		lock_button.set_pressed_no_signal(false)
		lock_button.icon = lock_icon
		lock_button.tooltip_text = ""
		lock_button.disabled = true

func _enter_tree():
	add_inspector_plugin(scene_inspector)
	
	var inspector_dock: Control = EditorInterface.get_base_control().find_children('*', 'InspectorDock', true, false)[0]
	var save_icon := EditorInterface.get_base_control().get_theme_icon('Save', 'EditorIcons')
	for button: Button in inspector_dock.find_children('*', 'Button', true, false):
		if button.icon == save_icon:
			lock_button = _create_lock_button()
			button.add_sibling(lock_button)
			break
			
	_update_lock()
	EditorInterface.get_inspector().edited_object_changed.connect(_update_lock)

func _exit_tree():
	remove_inspector_plugin(scene_inspector)
	if lock_button:
		lock_button.queue_free()
		lock_button = null
