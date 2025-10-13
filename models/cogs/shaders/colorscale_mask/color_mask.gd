extends CogShader
class_name ColorMask

## Textures
@export var base_tex: Texture2D
@export var mask_tex: Texture2D

## Colors
@export var base_color := Color.WHITE
@export var randomize_base_color := true
@export var mask_color := Color.WHITE
@export var randomize_mask_color := true

## Reference to color mask shader
const SHADER = preload('res://models/cogs/shaders/colorscale_mask/colorscale_mask.tres')


## Applies the color mask shader to a mesh instance
func apply_shader(mesh_instance: MeshInstance3D,surface := 0) -> void:
	var mask: VisualShader = SHADER.duplicate(true)
	var shader := ShaderMaterial.new()
	shader.shader = mask
	shader.set_shader_parameter('tex_frg_2', base_tex)
	shader.set_shader_parameter('tex_frg_3', mask_tex)
	shader.set_shader_parameter('base_color', base_color)
	shader.set_shader_parameter('mask_color', mask_color)
	mesh_instance.set_surface_override_material(surface, shader)

func randomize_shader() -> void:
	if randomize_base_color:
		base_color = Globals.random_dna_color
	if randomize_mask_color:
		mask_color = Globals.random_dna_color
