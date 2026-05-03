extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


var low_grav := "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_low_gravity.gd"


func setup() -> void:
	Util.s_floor_started.connect(on_floor_started)

func on_floor_started(gfloor: GameFloor) -> void:
	await get_tree().process_frame
	var node := Node.new()
	node.set_script(load(low_grav))
	add_child(node)
	node.game_floor = gfloor
	node.modify_floor()
	node.queue_free()
