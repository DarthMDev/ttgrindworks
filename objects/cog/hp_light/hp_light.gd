extends MeshInstance3D

# Signals
signal s_color_changed(light_color: Color, glow_color: Color)

func _ready() -> void:
	set_surface_override_material(0, get_surface_override_material(0).duplicate(true))
	$Glow.set_surface_override_material(0, $Glow.get_surface_override_material(0).duplicate(true))

func set_color(light_color: Color, glow_color: Color):
	get_surface_override_material(0).albedo_color = light_color
	$Glow.get_surface_override_material(0).albedo_color = glow_color
	s_color_changed.emit(light_color, glow_color)
