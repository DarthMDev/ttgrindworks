@tool
extends StatusEffect


var loadout
var barnacles = false

func apply() -> void:
	var player = Util.get_player()
	loadout = player.stats.character.gag_loadout.duplicate()
	#s_battle_ending
	manager.s_battle_ending.connect(battle_end)

func expire() -> void:
	if not loadout:
		return
	# Restore previous loadout
	var player := Util.get_player()
	player.stats.character.gag_loadout = loadout

func get_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/Reorganization.png")
func battle_end() -> void:
	clean_up()
func clean_up() -> void:
	if not loadout:
		return
	# Restore previous loadout
	var player := Util.get_player()
	player.stats.character.gag_loadout = loadout
	manager.s_battle_ending.disconnect(battle_end)

func combine(effect : StatusEffect) -> bool:
	return true
		
	
