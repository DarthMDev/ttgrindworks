@tool
extends EditorContextMenuPlugin

const GAME_FLOOR_SCENE_PATH := 'res://scenes/game_floor/game_floor.tscn'
var debugger: ToonlikeEditorDebuggerPlugin

func _init(_debugger: ToonlikeEditorDebuggerPlugin):
	debugger = _debugger

func is_floor_variant_script(path: String) -> bool:
	return (
		path.begins_with('res://scenes/game_floor/floor_variants/alt_floors/') or
		path.begins_with('res://scenes/game_floor/floor_variants/base_floors/')
	)

func _popup_menu(paths: PackedStringArray):
	if len(paths) == 1 and is_floor_variant_script(paths[0]):
		var floor_variant: FloorVariant = load(paths[0])
		if not floor_variant:
			return
		
		if floor_variant.override_scene:
			add_context_menu_item(
				'Run Floor Variant Override Scene (%s)' % floor_variant.override_scene.resource_path.get_file(),
				_run_override_scene.bind(floor_variant.override_scene.resource_path),
				EditorInterface.get_base_control().get_theme_icon('PlayCustom', 'EditorIcons')
			)
		add_context_menu_item(
			'Run GameFloor Scene with Floor Variant',
			_run_game_floor,
			EditorInterface.get_base_control().get_theme_icon('PlayCustom', 'EditorIcons')
		)

func _run_override_scene(_paths, override_scene: String):
	EditorInterface.play_custom_scene(override_scene)

func _run_game_floor(paths: PackedStringArray):
	EditorInterface.play_custom_scene(GAME_FLOOR_SCENE_PATH)
	debugger.session_ready_for.connect(_send_game_floor_floor_variant.bind(paths[0]), CONNECT_ONE_SHOT)

func _send_game_floor_floor_variant(session: EditorDebuggerSession, scene: String, path: String):
	if scene == debugger.GAME_FLOOR:
		session.send_message('toonlike:game_floor:set_floor_variant', [path])
