extends ItemScriptActive

const SFX := preload("res://audio/sfx/ui/tick_counter.ogg")

func use() -> void:
	
	var player_stats := Util.get_player().stats
	player_stats.add_money(RandomService.randi_channel('true_random') % 4 + 2)
	AudioManager.play_sound(SFX)
