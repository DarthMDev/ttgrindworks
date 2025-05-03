extends ActionScript
class_name BossLavaSink

func action():
	if manager.cogs.size() > 0 and not manager.cogs.size() == user.current_unit:
		manager.battle_node.battle_cam.global_transform = user.sink_pos.global_transform
		await user.sink_platform(manager.cogs.size())
