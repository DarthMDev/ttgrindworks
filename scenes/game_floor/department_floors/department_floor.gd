extends Resource
class_name DepartmentFloor

@export_custom(GameLoader.FILE_ARRAY, GameLoader.SCENE_ARRAY)
var entrances: PackedStringArray

@export var battle_rooms: Array[FacilityRoom]
@export var obstacle_rooms: Array[FacilityRoom]

@export_custom(GameLoader.FILE_ARRAY, GameLoader.SCENE_ARRAY)
var connectors: PackedStringArray

## Rooms that should show up RIGHT BEFORE the final boss.
@export var pre_final_rooms: Array[FacilityRoom]
@export var final_rooms: Array[FacilityRoom]

@export_custom(GameLoader.FILE_ARRAY, GameLoader.SCENE_ARRAY)
var one_time_rooms: PackedStringArray

## "Cool" rooms that, out of this entire selection, can only spawn ONCE per floor.
@export var special_rooms: Array[FacilityRoom]

## Music Defaults
@export_custom(GameLoader.FILE_ARRAY, GameLoader.AUDIO_STREAM_ARRAY)
var background_music: PackedStringArray

@export_file(GameLoader.AUDIO_STREAM) var battle_music: String


## Temporary holding of loaded rooms
var loaded_scenes: Array[PackedScene] = []
func load_all() -> void:
	for path in get_all_scene_paths():
		loaded_scenes.append(GameLoader.load(path))

func get_all_scene_paths() -> Array[String]:
	var paths: Array[String] = []
	var sources := [entrances, battle_rooms, obstacle_rooms, connectors, pre_final_rooms, final_rooms, one_time_rooms, special_rooms]
	for arr in sources:
		for entry in arr:
			if entry is String: paths.append(entry)
			elif entry is FacilityRoom: paths.append(entry.room)
	return paths
