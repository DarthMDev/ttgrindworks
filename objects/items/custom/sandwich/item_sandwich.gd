extends ItemScriptActive

const chomp = "res://audio/sfx/items/big_chomp.ogg"

func validate_use() -> bool:
	return not Util.get_player().stats.hp == Util.get_player().stats.max_hp

func use() -> void:
	var player := Util.get_player()
	
	player.quick_heal(roundi(player.stats.max_hp * 0.3))
	AudioManager.play_sound(load(chomp))
