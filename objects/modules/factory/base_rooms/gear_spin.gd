@tool
extends Node3D

@export var rotation_speed := 30.0

enum RotationType {X, Y, Z}

@export var rotation_type := RotationType.Y

func _process(delta: float) -> void: 
	match rotation_type:
		RotationType.X: rotation_degrees.x += rotation_speed * delta
		RotationType.Y: rotation_degrees.y += rotation_speed * delta
		RotationType.Z: rotation_degrees.z += rotation_speed * delta

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		match rotation_type:
			RotationType.X: rotation_degrees.x = 0
			RotationType.Y: rotation_degrees.y = 0
			RotationType.Z: rotation_degrees.z = 0
