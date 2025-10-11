@tool
extends Panel

@export_range(0.0,1.0) var value : float:
	set(x):
		value = clamp(x, 0.0, 1.0)
		update_value()

@onready var bar_shader : ShaderMaterial = $Mask/ProgressBar.material


func _process(_delta : float) -> void:
	update_texture()

func update_value() -> void:
	bar_shader.set_shader_parameter('ratio', value)

func update_texture() -> void:
	var noise : FastNoiseLite = bar_shader.get_shader_parameter('meter_tex').noise
	if not Engine.is_editor_hint():
		noise.seed = randi()
