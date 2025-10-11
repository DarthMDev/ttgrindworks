@tool
extends EditorDebuggerPlugin
class_name ToonlikeEditorDebuggerPlugin

const GAME_FLOOR = 'game_floor'
const DEBUG_PLAYER_POSITION_MARKER = 'debug_player_position_marker'

const SCENES = [
	GAME_FLOOR,
	DEBUG_PLAYER_POSITION_MARKER,
]

const RUN_PROJECT := 'Run Project'
const STOP_RUNNING_PROJECT := 'Stop Running Project'
const RUN_CURRENT_SCENE := 'Run Current Scene'
const RUN_SPECIFIC_SCENE := 'Run Specific Scene'

static var buttons: Dictionary[String, Button] = {
	RUN_PROJECT: null,
	STOP_RUNNING_PROJECT: null,
	RUN_CURRENT_SCENE: null,
	RUN_SPECIFIC_SCENE: null,
}

static func _static_init():
	var editor_run_bar: Control = EditorInterface.get_base_control().find_children('*', 'EditorRunBar', true, false)[0]
	for button: BaseButton in editor_run_bar.find_children('*', 'BaseButton', true, false):
		if button.shortcut and button.shortcut.resource_name in buttons:
			buttons[button.shortcut.resource_name] = button

func _init():
	if buttons[RUN_PROJECT]:
		buttons[RUN_PROJECT].connect('pressed', disable_persistent_injection.emit)
	if buttons[STOP_RUNNING_PROJECT]:
		buttons[STOP_RUNNING_PROJECT].connect('pressed', disable_persistent_injection.emit)
	if buttons[RUN_CURRENT_SCENE]:
		buttons[RUN_CURRENT_SCENE].connect('pressed', disable_persistent_injection.emit)

signal session_started(session: EditorDebuggerSession)
signal session_ready_for(session: EditorDebuggerSession, scene: String)
signal session_ended(session: EditorDebuggerSession)
signal disable_persistent_injection

func _has_capture(capture) -> bool:
	return capture == 'toonlike'
	
func _capture(message, data, session_id) -> bool:
	if message == 'toonlike:ready_for':
		session_ready_for.emit(get_session(session_id), data[0])
		return true
	return false

func _setup_session(session_id) -> void:
	var session := get_session(session_id)
	# Listens to the session started and stopped signals.
	session.started.connect(session_started.emit.bind(session))
	session.stopped.connect(session_ended.emit.bind(session))
