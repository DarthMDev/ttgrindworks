@tool
extends Node3D

@export var color: Color = Color.WHITE:
	set(x):
		color = x
		update_color()

func update_color() -> void:
	%conveyor_belt_portal.get_surface_override_material(2).albedo_color = color
