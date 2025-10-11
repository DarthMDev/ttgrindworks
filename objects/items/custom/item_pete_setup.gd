extends ItemCharSetup

func first_time_setup(player: Player) -> void:
	for key in player.stats.gag_vouchers.keys():
		player.stats.gag_vouchers[key] = 0
