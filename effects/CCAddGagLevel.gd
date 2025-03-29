extends CCEffect

class_name CCAddGagLevel


# adds a random gag level to the player (basically like unlocking a new track frame)

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	# reward a track frame
	var player = Util.get_player()
	var track_frame = ItemService.get_track_frame()
	track_frame.apply_item(player)
	track_frame.play_collection_sound()
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.update_battle_stats()
	return SUCCESS

func check_if_all_gags_maxxed() -> bool:
	var player = Util.get_player()
	var gags_unlocked = player.stats.gags_unlocked
	for gag_track in gags_unlocked:
		if gags_unlocked[gag_track] < 7:
			return false
	return true

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if not check_if_all_gags_maxxed():
		return true
	return false
