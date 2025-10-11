extends ItemCharSetup

func first_time_setup(player : Player) -> void:
	await get_tree().process_frame
	player.stats.max_hp = 1
	player.stats.hp = 1
