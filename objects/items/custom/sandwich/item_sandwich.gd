extends ItemScriptActive

const chomp = "res://audio/sfx/items/big_chomp.ogg"

const BANNED_SCENES: Array[String] = [
	'StrangerShop',
	'ElevatorScene',
]

func validate_use() -> bool:
	if SceneLoader.current_scene.name in BANNED_SCENES:
		return false
	return not Util.get_player().stats.hp == Util.get_player().stats.max_hp

func use() -> void:
	var player := Util.get_player()
	
	player.quick_heal(roundi(player.stats.max_hp * 0.3))
	AudioManager.play_sound(load(chomp))
