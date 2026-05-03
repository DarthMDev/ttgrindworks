extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


const BLUNDER_COUNTER := "res://objects/items/custom/seed_logic/collision_blunder_counter/collision_blunder_counter.tscn"

var ui: Control


func setup() -> void:
	ui = load(BLUNDER_COUNTER).instantiate()
	add_child(ui)
	
