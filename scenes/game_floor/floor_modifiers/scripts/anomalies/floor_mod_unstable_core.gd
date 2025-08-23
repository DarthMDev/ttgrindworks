extends FloorModifier

var desc_lock = false
func modify_floor() -> void:
	#game_floor.s_cog_spawned.connect(
	#	func(cog: Cog):
	#		cog.health_mod *= 1.2
	#
	#)
	desc_lock = true
	print(Util.floor_number)

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Unstable Core"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/radiation_hazard.png")

func get_description() -> String:
	if not desc_lock:
		if Util.floor_number == 6:
			return "Foremen have stronger cheats and higher health
Foreman lose the Basic Math Cheat and have a weaker compensation"
		if Util.floor_number == 7:
			return "Every battle will have 4 foremen and some foremen are getting a bit... quirky
Foreman will not force unlure after compensation and have an even weaker compensation
+1 battle start point boost
			"
	else:
		if Util.floor_number == 7:
				return "Foremen have stronger cheats and higher health
Foreman lose the Basic Math Cheat and have a weaker compensation"
		else:
				return "Every battle will have 4 foremen and some foremen are getting a bit... quirky
Foreman will not force unlure after compensation and have an even weaker compensation
+1 battle start point boost
				"
				#this is the 7th worse piece of "code" ive written in godot
	return "Cog HP is increased by 20%"
