@tool
extends EditorContextMenuPlugin

const GAME_FLOOR_SCENE_PATH := 'res://scenes/game_floor/game_floor.tscn'
var debugger: ToonlikeEditorDebuggerPlugin

func _init(_debugger: ToonlikeEditorDebuggerPlugin):
	debugger = _debugger

func is_floor_mod_script(path: String) -> bool:
	return path.begins_with('res://scenes/game_floor/floor_modifiers/scripts/anomalies/')

func _popup_menu(paths: PackedStringArray):
	if Array(paths).all(is_floor_mod_script):
		add_context_menu_item(
			'Run GameFloor Scene with Floor Mods',
			_run_game_floor,
			EditorInterface.get_base_control().get_theme_icon('PlayCustom', 'EditorIcons')
		)

func _run_game_floor(paths: PackedStringArray):
	EditorInterface.play_custom_scene(GAME_FLOOR_SCENE_PATH)
	debugger.session_ready_for.connect(_send_game_floor_floor_mods.bind(paths), CONNECT_ONE_SHOT)

func _send_game_floor_floor_mods(session: EditorDebuggerSession, scene: String, paths: PackedStringArray):
	if scene == debugger.GAME_FLOOR:
		session.send_message('toonlike:game_floor:add_floor_mods', Array(paths))
