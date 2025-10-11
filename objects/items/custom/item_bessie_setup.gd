extends ItemCharSetup


func first_time_setup(player : Player) -> void:
	# Bessie does not naturally get this set since Drop is not in her loadout
	player.stats.gag_effectiveness['Drop'] = 1.0
