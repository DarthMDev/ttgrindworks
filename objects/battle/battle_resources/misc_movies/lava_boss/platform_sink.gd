extends ActionScript
class_name BossLavaSink

const SINK_MIN := -2

func action():
	if manager.cogs.size() == 0:
		return
	var sink_units := mini(SINK_MIN + manager.cogs.size(), 2)
	manager.battle_node.battle_cam.global_transform = user.sink_pos.global_transform
	await user.do_increment(sink_units)
