extends ItemScriptActive

const chomp = "res://audio/sfx/items/big_chomp.ogg"

func use() -> void:
	var player = Util.get_player()
	AudioManager.play_sound(load(chomp))
	player.do_invincibility_frames(10.0)
