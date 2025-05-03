extends ItemScriptActive

const SFX_PRESS := preload("res://audio/sfx/battle/gags/AA_trigger_box.ogg")

func use() -> void:
	for track : TrackElement in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
		track.free = true
		track.refresh()
	BattleService.ongoing_battle.s_round_started.connect(on_round_start)
	AudioManager.play_sound(SFX_PRESS)

func on_round_start(_actions) -> void:
	for track : TrackElement in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
		track.free = false
