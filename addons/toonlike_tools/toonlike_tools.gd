@tool
extends EditorPlugin

#region Injectors
const ANOMALY_INJECTOR := preload('res://addons/toonlike_tools/injectors/anomaly_injector.gd')
var anomaly_injection_plugin: EditorContextMenuPlugin

const FLOOR_VARIANT_INJECTOR := preload('res://addons/toonlike_tools/injectors/floor_variant_injector.gd')
var floor_variant_injector_plugin: EditorContextMenuPlugin

const PLAYER_INJECTOR := preload('res://addons/toonlike_tools/injectors/player/player_injector.gd')
var player_injector: Control
#endregion

var debugger := ToonlikeEditorDebuggerPlugin.new()

var add_player_context_menu_option: EditorContextMenuPlugin

func _enter_tree():
	add_autoload_singleton("Logging", "res://addons/toonlike_tools/logging/logging.gd")
	add_custom_type("Logger", "RefCounted", preload("logging/logger.gd"), preload("logging/GuiTabMenu.svg"))

	add_debugger_plugin(debugger)
	#region Injectors
	anomaly_injection_plugin = ANOMALY_INJECTOR.new(debugger)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, anomaly_injection_plugin)
	
	floor_variant_injector_plugin = FLOOR_VARIANT_INJECTOR.new(debugger)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, floor_variant_injector_plugin)
	
	player_injector = PLAYER_INJECTOR.new(self, debugger)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, player_injector)
	#endregion
	
	add_tool_menu_item('[Add-on] Clear Godot cache and reload current project', clear_godot_cache_and_restart)

func _exit_tree():
	remove_autoload_singleton("Logging")
	remove_custom_type("Logger")

	remove_debugger_plugin(debugger)
	#region Injectors
	if anomaly_injection_plugin:
		remove_context_menu_plugin(anomaly_injection_plugin)
	anomaly_injection_plugin = null
	
	if floor_variant_injector_plugin:
		remove_context_menu_plugin(floor_variant_injector_plugin)
	floor_variant_injector_plugin = null
	
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
