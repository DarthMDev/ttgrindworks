@tool
extends TextureRect

## Randomize the static every frame
func _process(_delta : float) -> void:
	var static_texture : FastNoiseLite = texture.noise
	static_texture.seed = randi()

func set_alpha(alpha : float) -> void:
	modulate.a = alpha
