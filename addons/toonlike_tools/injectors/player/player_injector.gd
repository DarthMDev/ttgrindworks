@tool
extends HBoxContainer

const DEBUG_PLAYER_POSITION_MARKER := preload('debug_player_position_marker.tscn')
const VALID_PLAYER_PATHS: PackedStringArray = [
	'res://objects/modules/',
	'res://scenes/cog_building/',
	'res://scenes/final_boss/',
]

var main_plugin: EditorPlugin
var debugger: ToonlikeEditorDebuggerPlugin
@onready var check_button: CheckButton = $CheckButton
var marker_pos: Vector3

func _init(_main_plugin: EditorPlugin, _debugger: ToonlikeEditorDebuggerPlugin):
	main_plugin = _main_plugin
	debugger = _debugger

	var player_icon = TextureRect.new()
	player_icon.texture = EditorInterface.get_base_control().get_theme_icon(
		'CharacterBody3D', 'EditorIcons'
	)
	player_icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	player_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	add_child(VSeparator.new())
	add_child(player_icon)
	add_child(CheckButton.new(), true)
	tooltip_text = 'Add Player when Running Current Scene'

func _ready():
	main_plugin.scene_changed.connect(_on_scene_changed)
	_on_scene_changed(EditorInterface.get_edited_scene_root())
	debugger.session_ready_for.connect(_send_player)
	check_button.toggled.connect(_on_check_button_toggled)

func _on_scene_changed(scene_root: Node):
	if not scene_root or not scene_root.scene_file_path:
		check_button.button_pressed = false
		check_button.disabled = true
		return
		
	for path in VALID_PLAYER_PATHS:
		if scene_root.scene_file_path.begins_with(path):
			check_button.disabled = false
			var marker: Marker3D = scene_root.find_child('DebugPlayerPositionMarker')
			check_button.button_pressed = marker != null
			if marker:
				marker_pos = marker.global_position
			return
	check_button.button_pressed = false
	check_button.disabled = true

func _on_check_button_toggled(toggled_on: bool):
	var marker = EditorInterface.get_edited_scene_root().find_child('DebugPlayerPositionMarker')
	if toggled_on and not marker:
		var scene_root := EditorInterface.get_edited_scene_root()
		marker = DEBUG_PLAYER_POSITION_MARKER.instantiate()
		scene_root.add_child(marker)
		marker.owner = scene_root
		EditorInterface.edit_node(marker)
		EditorInterface.mark_scene_as_unsaved()
	elif not toggled_on and marker:
		marker.queue_free()
		EditorInterface.mark_scene_as_unsaved()

func _send_player(session: EditorDebuggerSession, scene: String):
	if scene == debugger.DEBUG_PLAYER_POSITION_MARKER and check_button.button_pressed:
		session.send_message('toonlike:debug_player_position_marker:inject_player', [marker_pos])
