extends FloorModifier

var gag_loadout: GagLoadout


func modify_floor() -> void:
	var player := Util.get_player()
	
	if not player:
		return
	
	# Save a copy of the base gag loadout
	gag_loadout = player.stats.character.gag_loadout

	# Shuffle the player's current loadout
	var _new_loadout: GagLoadout = gag_loadout.duplicate()
	_new_loadout.loadout = _new_loadout.loadout.duplicate()
	RNG.channel(RNG.ChannelAnomalyReorg).shuffle(_new_loadout.loadout)
	player.stats.character.gag_loadout = _new_loadout

func clean_up() -> void:
	if not gag_loadout:
		return
	# Restore previous loadout
	var player := Util.get_player()
	player.stats.character.gag_loadout = gag_loadout

func get_mod_name() -> String:
	return "Reorganization"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/Reorganization.png")

func get_description() -> String:
	return "Gag tracks are randomly shuffled"
