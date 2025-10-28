extends CogShader
class_name RainbowMask

## Textures
@export var base_tex : Texture2D
@export var mask_tex : Texture2D

## Locals
var mesh : MeshInstance3D
var colors := [Color.RED,Color.ORANGE,Color.YELLOW,Color.GREEN,Color.BLUE,Color.INDIGO,Color.VIOLET]
var mask_color := Color.WHITE
var base_color := Color.WHITE
var shader_mat : ShaderMaterial

## Reference to color mask shader
const SHADER = preload('res://models/cogs/shaders/colorscale_mask/colorscale_mask.tres')


func apply_shader(mesh_instance: MeshInstance3D, surface := 0) -> void:
	var mask : VisualShader = SHADER.duplicate(true)
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = mask
	shader_mat.set_shader_parameter('tex_frg_2',base_tex)
	shader_mat.set_shader_parameter('tex_frg_3',mask_tex)
	mesh_instance.set_surface_override_material(surface,shader_mat)
	_process()

## Was done to test something but this is actually a seizure risk
## Don't recommend uncommenting that while statement
func _process() -> void:
	while true:
		await Util.get_tree().process_frame
		if shader_mat:
			shader_mat.set_shader_parameter('base_color',colors[randi()%colors.size()])
			shader_mat.set_shader_parameter('mask_color',colors[randi()%colors.size()])
