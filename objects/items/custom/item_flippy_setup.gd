extends ItemCharSetup

const PAINT_BUCKET_PATH := "res://objects/items/resources/active/paint_bucket.tres"

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	stats.gag_effectiveness['Throw'] = 1.05
