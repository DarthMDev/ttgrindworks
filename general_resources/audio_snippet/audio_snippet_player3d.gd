@tool
extends Node3D
class_name AudioSnippetPlayer3D

enum AudioBus {}

func _validate_property(property: Dictionary):
	if property.name == "bus":
		var busNumber = AudioServer.bus_count
		var options = ""
		for i in busNumber:
			if i > 0:
				options += ","
			var busName = AudioServer.get_bus_name(i)
			options += busName
		property.hint_string = options

@export var snippet: AudioSnippet:
	set(x):
		snippet = x

@export_category("AudioStreamPlayer3D")
@export var attenuation_model := AudioStreamPlayer3D.AttenuationModel.ATTENUATION_INVERSE_DISTANCE
@export_range(-80.0, 80.0, 0.01) var volume_db = 0.0
@export_range(0.1, 100.0, 0.01) var unit_size := 10.0
@export_range(-24.0, 6.0, 0.01) var max_db := 3.0
@export_range(0.01, 4.0, 0.01) var pitch_scale := 1.0
@export var autoplay := false
@export var bus: AudioBus

var audio_player: AudioStreamPlayer3D
var timer: Timer

signal s_played
signal s_finished


func _ready() -> void:
	_prepare_audio_player()
	_prepare_timer()
	if autoplay: play()

func _prepare_audio_player() -> void:
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
	
	for property in ['attenuation_model', 'volume_db', 'unit_size', 'max_db', 'pitch_scale', 'bus']:
		audio_player.set(property, get(property))
	audio_player.stream = snippet.stream
	
	add_child(audio_player)

func play() -> void:
	s_played.emit()
	start_timer()
	audio_player.play(snippet.start_time)

func stop() -> void:
	if audio_player.playing:
		audio_player.stop()
		timer.stop()

func start_timer() -> void:
	if is_equal_approx(snippet.end_time, -1.0):
		timer.wait_time = snippet.stream.get_length() - snippet.start_time
	else:
		timer.wait_time = snippet.end_time - snippet.start_time
	timer.start()

func _on_timer_timeout() -> void:
	s_finished.emit()
	audio_player.stop()

func _prepare_timer() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
