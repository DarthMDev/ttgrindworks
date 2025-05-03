@tool
extends Node3D

@export var water_color := Color.WHITE:
	set(x):
		if not is_node_ready():
			await ready
		water_color = x
		water_mat.set_shader_parameter('color_parameter', x)
		splash_mat.albedo_color = x
	get:
		return splash_mat.albedo_color

@onready var water_mat : ShaderMaterial = %geyserRise.get_surface_override_material(0)
@onready var splash_mat : StandardMaterial3D = %GPUParticles3D.draw_pass_1.material
