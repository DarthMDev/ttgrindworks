extends Node

var game_floor: GameFloor:
	get: return Util.floor_manager

@export var interactive_stream: AudioStreamInteractive:
	set(x):
		interactive_stream = x
		setup()


func setup() -> void:
	pass

func get_room_type() -> GameFloor.RoomType:
	return game_floor.get_current_room_type()
