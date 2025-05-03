extends ItemCharSetup

func first_time_setup(player: Player) -> void:
	player.stats.gags_unlocked['Trap'] = 2
	player.stats.gags_unlocked['Lure'] = 2
	player.stats.luck = 1.05
