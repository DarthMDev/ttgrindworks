extends Node3D

## Area is for *camera* detection.
## Camera position determines the newest safe respawn point
@export var respawn_points: Dictionary[Area3D, Node3D] = {}

signal s_respawn_point_reached(respawn_point: Node3D)

func _ready() -> void:
	for area: Area3D in respawn_points.keys():
		area.area_entered.connect(on_area_entered.bind(respawn_points[area]))

func on_area_entered(area: Area3D, respawn_pt: Node3D) -> void:
	if area.name == "ChaseCamCollide":
		s_respawn_point_reached.emit(respawn_pt)
