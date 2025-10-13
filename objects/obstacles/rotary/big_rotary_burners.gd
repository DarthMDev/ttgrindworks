@tool
extends "res://objects/obstacles/spinning_gear/spinning_gear.gd"

## idk what the hell this is i'm not touching it
## -evan

@onready var burner_groups : Array[Node3D] = [
%BurnerGroups,
%BurnerGroups2,
%BurnerGroups3,
%BurnerGroups4,
%BurnerGroups5,
%BurnerGroups6
]
@onready var burner_positions: Array[Marker3D] = [
	$BurnerPosition1,
	$BurnerPosition2,
	$BurnerPosition3
]

func _ready():
	if Engine.is_editor_hint():
		return
	for marker in burner_positions:
		var group_index = randi_range(0, burner_groups.size() - 1)
		var group = burner_groups.pop_at(group_index)
		group.rotation_degrees.y = randi_range(0, 360)
		
		group.global_position = marker.global_position
	for group in burner_groups:
		group.queue_free()
	return
