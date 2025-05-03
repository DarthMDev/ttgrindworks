extends ItemCharSetup

const PAINT_BUCKET_PATH := "res://objects/items/resources/active/paint_bucket.tres"

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	player.stats.gags_unlocked['Squirt'] = 1
	player.stats.gags_unlocked['Throw'] = 1
	stats.gag_effectiveness['Throw'] = 1.05
	stats.luck = 1.05
	
	if SaveFileService.progress_file.achievements_earned[ProgressFile.GameAchievement.FLIPPY_GETS_BUCKET]:
		if player.stats.current_active_item:
			player.stats.current_active_item = null
		player.stats.current_active_item = GameLoader.load(PAINT_BUCKET_PATH).duplicate()
