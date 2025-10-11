@tool
extends Control

func _ready() -> void:
	$Timer.start()

func swap_visibility() -> void:
	$ArrowContainer.visible = not $ArrowContainer.visible

func _process(_delta):
	for child: TextureRect in $ArrowContainer.get_children():
		var mat: ShaderMaterial = child.material
		mat.set_shader_parameter(&'alpha', modulate.a)
