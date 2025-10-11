@tool
extends EditorContextMenuPlugin

const GAME_FLOOR_SCENE_PATH := 'res://scenes/game_floor/game_floor.tscn'
var debugger: ToonlikeEditorDebuggerPlugin

func _init(_debugger: ToonlikeEditorDebuggerPlugin):
	debugger = _debugger
	debugger.disable_persistent_injection.connect(_disable_persistent_injection)


func _disable_persistent_injection():
	if debugger.session_ready_for.is_connected(_send_game_floor_variant):
		debugger.session_ready_for.disconnect(_send_game_floor_variant)


func is_floor_variant_script(path: String) -> bool:
	return (
		path.begins_with('res://scenes/game_floor/floor_variants/alt_floors/') or
		path.begins_with('res://scenes/game_floor/floor_variants/base_floors/')
	)


func _popup_menu(paths: PackedStringArray):
	if len(paths) == 1 and is_floor_variant_script(paths[0]):
		add_context_menu_item(
			'Test Floor Variant',
			_run_game_floor,
			EditorInterface.get_base_control().get_theme_icon('PlayCustom', 'EditorIcons')
		)


func _run_override_scene(override_scene: String):
	EditorInterface.play_custom_scene(override_scene)


func _run_game_floor(paths: PackedStringArray):
	var floor_variant: FloorVariant = load(paths[0])
	if not floor_variant:
		return
	
	if floor_variant.override_scene:
		_run_override_scene(floor_variant.override_scene.resource_path)
	else:
		EditorInterface.play_custom_scene(GAME_FLOOR_SCENE_PATH)
		debugger.session_ready_for.connect(_send_game_floor_variant.bind(paths[0]))


func _send_game_floor_variant(session: EditorDebuggerSession, scene: String, path: String):
	if scene == debugger.GAME_FLOOR:
		session.send_message('toonlike:game_floor:set_floor_variant', [path])
