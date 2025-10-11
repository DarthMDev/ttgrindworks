extends DepartmentFloor
class_name RoomPack

enum PackMode {
	ADD,
	REPLACE
}

@export var entrance_mode := PackMode.ADD
@export var battle_mode := PackMode.ADD 
@export var obstacle_mode := PackMode.ADD
@export var connector_mode := PackMode.ADD 
@export var pre_final_mode := PackMode.ADD
@export var final_mode := PackMode.ADD
@export var special_mode := PackMode.ADD
@export var one_time_mode := PackMode.ADD
