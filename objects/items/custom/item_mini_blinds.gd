extends ItemScript

const CHANGE_CHANCE := 0.1
## Some tracks should try to increment multiple levels
const STEPPED_TRACKS: Dictionary = {
	'Lure': 2
}

func setup() -> void:
	BattleService.s_round_started.connect(on_round_start)

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack:
			if RandomService.randf_channel('true_random') < CHANGE_CHANCE:
				change_gag(action)

func change_gag(action: ToonAttack) -> void:
	var gag_index := get_gag_index(action)
	if gag_index == -1:
		return

	var track: Track = find_track(action)
	var unlocked := get_gags_unlocked(track.track_name)
	gag_index += STEPPED_TRACKS.get(track.track_name, 1)
	if gag_index < 0 or gag_index >= unlocked:
		return
	else:
		replace_gag(action, find_track(action).gags[gag_index].duplicate())

func replace_gag(gag: ToonAttack, new_gag: ToonAttack) -> void:
	var battle := BattleService.ongoing_battle
	if not is_instance_valid(BattleService.ongoing_battle):
		return
	
	# Assign the correct targets to the new gag
	if gag.target_type == new_gag.target_type:
		new_gag.targets = gag.targets
		new_gag.main_target = gag.main_target
	else:
		return
	#elif new_gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		#new_gag.main_target = gag.targets[0]
		#new_gag.reassess_splash_targets(battle.cogs.find(gag.targets[0]), battle)

	new_gag.user = gag.user
	new_gag.store_boost_text("Level Up!", Color(1, 0.431, 0))
	battle.inject_battle_action(new_gag, battle.round_actions.find(gag))
	battle.round_actions.erase(gag)

func get_gags_unlocked(track: String) -> int:
	if Util.get_player():
		return Util.get_player().stats.gags_unlocked[track]
	return -1

func get_gag_index(action: ToonAttack) -> int:
	var track := find_track(action)
	if track:
		var filtered: Array = track.gags.filter(func(x: ToonAttack): return action.action_name == x.action_name)
		if filtered:
			return track.gags.find(filtered[0])
	return -1

func find_track(action: ToonAttack) -> Track:
	if not Util.get_player(): return null
	
	var gag_loadout := Util.get_player().stats.character.gag_loadout.loadout
	for track: Track in gag_loadout:
		for gag: ToonAttack in track.gags:
			if gag.action_name == action.action_name:
				return track
	return null

func on_collect(_item, _model) -> void:
	setup()

func on_load(_item) -> void:
	setup()
