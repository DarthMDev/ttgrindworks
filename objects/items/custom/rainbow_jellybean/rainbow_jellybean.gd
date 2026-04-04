@tool
extends Node3D

const COLORS := [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.DEEP_SKY_BLUE, Color.VIOLET]


func _ready() -> void:
	return
	var mat1: StandardMaterial3D = $jellybean2/Jellybean_all/jellybean.get_surface_override_material(0)
	var mat2: StandardMaterial3D = $jellybean2/Jellybean_all/Jellybeanhilight.get_surface_override_material(0)
	
	var rainbow_tween := create_tween().set_loops()
	for color in COLORS:
		rainbow_tween.tween_property(mat1, 'albedo_color', color, 2.0)
		rainbow_tween.parallel().tween_property(mat2, 'albedo_color', color, 2.0)
