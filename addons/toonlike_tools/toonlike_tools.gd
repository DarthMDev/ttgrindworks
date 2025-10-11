@tool
extends EditorPlugin

#region Inspectors
const FILE_INSPECTOR := preload('res://addons/toonlike_tools/inspectors/file_inspector.gd')
var file_inspector_plugin: EditorInspectorPlugin

#region Injectors
const ANOMALY_INJECTOR := preload('res://addons/toonlike_tools/injectors/anomaly_injector.gd')
var anomaly_injection_plugin: EditorContextMenuPlugin

const FLOOR_VARIANT_INJECTOR := preload('res://addons/toonlike_tools/injectors/floor_variant_injector.gd')
var floor_variant_injector_plugin: EditorContextMenuPlugin

const LABEL_CONVERTER_INJECTOR := preload("res://addons/toonlike_tools/injectors/label_converter_injector.gd")
var label_converter_injector_plugin: EditorContextMenuPlugin

const PLAYER_INJECTOR := preload('res://addons/toonlike_tools/injectors/player/player_injector.gd')
var player_injector: Control
#endregion

var debugger := ToonlikeEditorDebuggerPlugin.new()

var add_player_context_menu_option: EditorContextMenuPlugin


func _enter_tree():
	add_autoload_singleton("Logging", "res://addons/toonlike_tools/logging/logging.gd")
	add_custom_type("DebugLogger", "RefCounted", preload("logging/logger.gd"), preload("logging/GuiTabMenu.svg"))

	add_debugger_plugin(debugger)
	add_tool_menu_item("Resave All Resources", _request_resave)
	
	#region Inspectors
	file_inspector_plugin = FILE_INSPECTOR.new()
	add_inspector_plugin(file_inspector_plugin)
	#endregion
	
	#region Injectors
	anomaly_injection_plugin = ANOMALY_INJECTOR.new(debugger)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, anomaly_injection_plugin)
	
	floor_variant_injector_plugin = FLOOR_VARIANT_INJECTOR.new(debugger)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, floor_variant_injector_plugin)
	
	label_converter_injector_plugin = LABEL_CONVERTER_INJECTOR.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, label_converter_injector_plugin)
	
	player_injector = PLAYER_INJECTOR.new(self, debugger)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, player_injector)
	#endregion
	
	add_tool_menu_item('[Add-on] Clear Godot cache and reload current project', clear_godot_cache_and_restart)


func _exit_tree():
	remove_autoload_singleton("Logging")
	remove_custom_type("DebugLogger")

	remove_debugger_plugin(debugger)
	remove_tool_menu_item("Resave All Resources")
	
	#region Inspectors
	if file_inspector_plugin:
		remove_inspector_plugin(file_inspector_plugin)
	#endregion
	
	#region Injectors
	if anomaly_injection_plugin:
		remove_context_menu_plugin(anomaly_injection_plugin)
	anomaly_injection_plugin = null
	
	if floor_variant_injector_plugin:
		remove_context_menu_plugin(floor_variant_injector_plugin)
	floor_variant_injector_plugin = null
	
	if label_converter_injector_plugin:
		remove_context_menu_plugin(label_converter_injector_plugin)
		label_converter_injector_plugin = null
	
	if player_injector:
		remove_control_from_container(CONTAINER_TOOLBAR, player_injector)
		player_injector.queue_free()
		player_injector = null
	#endregion
	
	remove_tool_menu_item('[Add-on] Clear Godot cache and reload current project')


func clear_godot_cache_and_restart():
	for file in DirAccess.get_files_at('res://.godot/editor'):
		DirAccess.remove_absolute('res://.godot/editor/' + file)
	EditorInterface.restart_editor(false)

#region Resource Resave

func _request_resave():
	var w := ConfirmationDialog.new()
	w.dialog_text = "This tool will resave all resources and scenes in a project.\n\nAll files within a project may be modified. Make a backup/commit of your project before running.\n\nAre you ready?"
	w.confirmed.connect(_resave)
	get_editor_interface().popup_dialog_centered(w)

func _resave():
	var resource_fps := PathLoader.load_filepaths("res://", "", true, Resource)
	
	var valid_suffixes := ['.tres', '.res', '.tscn']
	
	print('Processing %s resources' % resource_fps.size())
	for fp: String in resource_fps:
		if fp.begins_with('res://.godot'): continue
		for suffix in valid_suffixes:
			if fp.ends_with(suffix):
				_safe_save(fp)
	
	print('Complete')

func _safe_save(fp: String):
	if not fp:
		return null
	var res = load(fp)
	if not res or not res.resource_path:
		return null
	ResourceSaver.save(res)


#endregion
