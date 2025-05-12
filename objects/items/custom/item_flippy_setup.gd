extends ItemCharSetup

const PAINT_BUCKET_PATH := "res://objects/items/resources/active/paint_bucket.tres"

func first_time_setup(player : Player) -> void:
	var stats := player.stats
	player.stats.gags_unlocked['Squirt'] = 1
	player.stats.gags_unlocked['Throw'] = 1
	stats.gag_effectiveness['Throw'] = 1.05
	stats.luck = 1.05
	
	var paint_bucket: ItemActive = GameLoader.load(PAINT_BUCKET_PATH)
	if not paint_bucket in ItemService.seen_items:
		ItemService.seen_item(paint_bucket)
	if SaveFileService.progress_file.achievements_earned[ProgressFile.GameAchievement.FLIPPY_GETS_BUCKET]:
		if player.stats.current_active_item:
			player.stats.current_active_item = null
		player.stats.current_active_item = paint_bucket.duplicate()
	
