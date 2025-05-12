extends ItemCharSetup


func first_time_setup(player : Player) -> void:
	player.stats.gags_unlocked['Squirt'] = 1
	player.stats.gags_unlocked['Lure'] = 1
	# Bessie does not naturally get this set since Drop is not in her loadout
	player.stats.gag_effectiveness['Drop'] = 1.0
	player.stats.luck = 1.1
