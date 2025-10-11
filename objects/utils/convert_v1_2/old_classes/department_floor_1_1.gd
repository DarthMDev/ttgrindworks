extends Resource

const FACILITY_ROOM := preload('uid://dhyadt7p1gv78')

@export var entrances : Array[PackedScene]

@export var battle_rooms: Array[FACILITY_ROOM]
@export var obstacle_rooms: Array[FACILITY_ROOM]
@export var connectors: Array[PackedScene]
## Rooms that should show up RIGHT BEFORE the final boss.
@export var pre_final_rooms: Array[FACILITY_ROOM]
@export var final_rooms: Array[FACILITY_ROOM]
@export var one_time_rooms: Array[PackedScene]
## "Cool" rooms that, out of this entire selection, can only spawn ONCE per floor.
@export var special_rooms: Array[FACILITY_ROOM]

## Music Defaults
@export var background_music : Array[AudioStream]
@export var battle_music : AudioStream
