extends ItemScriptActive

const chomp = "res://audio/sfx/items/big_chomp.ogg"

func use() -> void:
	var player := Util.get_player()
	
	if player.stats.hp == player.stats.max_hp:
		cancel_use()
		return
		
	player.quick_heal(player.stats.max_hp * 0.4)
	AudioManager.play_sound(load(chomp))
