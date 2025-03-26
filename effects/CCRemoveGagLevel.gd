extends CCEffect

class_name CCRemoveGagLevel

# removes a random gag level from the player

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	var loadout : GagLoadout = player.stats.character.gag_loadout
	var gag_tracks_unlocked = player.stats.gags_unlocked
	var track_name = loadout.loadout[randi() % loadout.loadout.size()].track_name
	if gag_tracks_unlocked[track_name] >= 1:
		gag_tracks_unlocked[track_name] -= 1
	else:
		return FAILURE
	return SUCCESS

func check_if_all_gags_minned() -> bool:
	var player = Util.get_player()
	var gag_tracks_unlocked = player.stats.gags_unlocked

	for gag_track in gag_tracks_unlocked:
		if gag_tracks_unlocked[gag_track] > 0:
			return false
	return true

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if not check_if_all_gags_minned():
		return true
	return false
