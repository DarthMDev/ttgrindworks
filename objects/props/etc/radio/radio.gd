extends Node3D

const MAX_DIST := 20.0

@onready var music_player : AudioStreamPlayer3D = $AudioPlayer

func _ready() -> void:
	music_player.finished.connect(func(): music_player.play())
	Globals.s_radio_spawned.emit(self)

func _process(_delta : float) -> void:
	var player_dist := get_player_distance()
	
	if player_dist >= MAX_DIST:
		mute()
	else:
		adjust_volume(player_dist)

func get_player_distance() -> float:
	if not Util.get_player():
		return MAX_DIST - 1.0
	return global_position.distance_to(Util.get_player().global_position)

func adjust_volume(distance : float) -> void:
	var adjusted_volume := -MAX_DIST + distance
	music_player.volume_db = -distance
	AudioManager.set_music_volume(adjusted_volume)

func mute() -> void:
	if music_player.volume_db > -100.0:
		music_player.volume_db = -100.0
		AudioManager.set_music_volume(0.0)
