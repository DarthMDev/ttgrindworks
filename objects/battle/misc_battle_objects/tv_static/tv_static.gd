@tool
extends TextureRect

@export_range(0.0, 1.0) var alpha : float:
	set(x):
		alpha = x
		update_alpha()

signal s_alpha_changed(alpha : float)

var bg : ColorRect


func _ready() -> void:
	material = material.duplicate(true)
	bg = ColorRect.new()
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
	
	bg.material = material.duplicate(true)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#bg.show_behind_parent = true
	#bg.hide()

## Randomize the static every frame
func _process(_delta : float) -> void:
	var static_texture : FastNoiseLite = texture.noise
	static_texture.seed = randi()

## Sets alpha and emits the signal
func set_alpha(new_alpha : float) -> void:
	alpha = new_alpha


func update_alpha(new_alpha := alpha) -> void:
	var mat : ShaderMaterial = material
	var a := 1.0 - new_alpha
	mat.set_shader_parameter('alpha_high', a)
	mat.set_shader_parameter('alpha_low', a * 0.0)
	mat.set_shader_parameter('base_alpha', new_alpha / 2.0)
	s_alpha_changed.emit(alpha)
	if bg:
		update_bg(new_alpha)

func update_bg(new_alpha : float) -> void:
	var mat : ShaderMaterial = bg.material
	var a := 1.0 - new_alpha
	mat.set_shader_parameter('alpha_high', a )
	mat.set_shader_parameter('alpha_low', 0.0)
	mat.set_shader_parameter('base_alpha', new_alpha / 4.0)
	s_alpha_changed.emit(alpha)

func get_alpha() -> float:
	return alpha
