extends ItemCharSetup

func first_time_setup(player : Player) -> void:
	player.stats.gags_unlocked['Sound'] = 1
	player.stats.gags_unlocked['Drop'] = 1
	player.stats.luck = 1.05
