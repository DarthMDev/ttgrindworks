extends ItemCharSetup

func first_time_setup(player : Player) -> void:
	for track in player.stats.gags_unlocked.keys():
		player.stats.gags_unlocked[track] = 1
	player.stats.luck = 1.3
	player.stats.crit_mult = 1.5
