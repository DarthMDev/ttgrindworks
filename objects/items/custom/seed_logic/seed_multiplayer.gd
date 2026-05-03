extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

func setup() -> void:
	await Util.s_floor_started
	SceneLoader.load_into_scene("res://objects/items/custom/seed_logic/disconnect_joke/authenticating.tscn")
