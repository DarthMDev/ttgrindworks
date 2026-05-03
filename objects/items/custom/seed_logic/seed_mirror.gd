extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


const MIRROR := "res://objects/items/custom/seed_logic/mirror.tscn"
var mirror: CanvasLayer

func setup() -> void:
	mirror = load(MIRROR).instantiate()
	add_child(mirror)
