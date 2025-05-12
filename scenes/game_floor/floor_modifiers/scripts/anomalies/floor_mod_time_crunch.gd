extends FloorModifier

const BATTLE_TIME := 20

func modify_floor() -> void:
	var player := Util.get_player()
	player.stats.battle_timers.append(BATTLE_TIME)

func clean_up() -> void:
	var player := Util.get_player()
	player.stats.battle_timers.erase(BATTLE_TIME)

func get_mod_name() -> String:
	return "Time Crunch"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/time_crunch.png")

func get_description() -> String:
	return "Adds a 20 second battle timer"

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE
