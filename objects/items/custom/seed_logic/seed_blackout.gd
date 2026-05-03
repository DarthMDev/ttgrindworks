extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


var power_out := "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_power_out.gd"


func setup() -> void:
	Util.s_floor_started.connect(on_floor_started)

func on_floor_started(gfloor: GameFloor) -> void:
	await get_tree().process_frame
	var node := Node.new()
	node.set_script(load(power_out))
	add_child(node)
	node.game_floor = gfloor
	node.modify_floor()
	node.queue_free()
