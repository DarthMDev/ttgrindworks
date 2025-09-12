extends Resource
class_name DepartmentFloor

@export var entrances : Array[PackedScene]

@export var battle_rooms: Array[FacilityRoom]
@export var obstacle_rooms: Array[FacilityRoom]
@export var connectors: Array[PackedScene]
## Rooms that should show up RIGHT BEFORE the final boss.
@export var pre_final_rooms: Array[FacilityRoom]
@export var final_rooms: Array[FacilityRoom]
@export var one_time_rooms: Array[PackedScene]
## "Cool" rooms that, out of this entire selection, can only spawn ONCE per floor.
@export var special_rooms: Array[FacilityRoom]

## Music Defaults
@export var background_music : Array[AudioStream]
@export var battle_music : Array[AudioStream]
