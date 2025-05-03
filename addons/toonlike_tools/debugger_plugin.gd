@tool
extends EditorDebuggerPlugin
class_name ToonlikeEditorDebuggerPlugin

const GAME_FLOOR = 'game_floor'
const DEBUG_PLAYER_POSITION_MARKER = 'debug_player_position_marker'

const SCENES = [
	GAME_FLOOR,
	DEBUG_PLAYER_POSITION_MARKER,
]

signal session_started(session: EditorDebuggerSession)
signal session_ready_for(session: EditorDebuggerSession, scene: String)
signal session_ended(session: EditorDebuggerSession)

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
