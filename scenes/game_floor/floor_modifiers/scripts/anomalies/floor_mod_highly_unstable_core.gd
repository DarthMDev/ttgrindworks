extends FloorModifier

## Gives all cogs on the floor 20 percent more health
func modify_floor() -> void:
	Util.unstable_chance = 30
	game_floor.s_cog_spawned.connect(
		func(cog: Cog):
			cog.health_mod *= 1.11
	)
	print(Util.floor_number)
	
func clean_up() -> void:
	Util.unstable_chance = 20
func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Highly Unstable Core"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/nuclear_icon.png")

func get_description() -> String:
	return "1.11x cog health multiplier
+10% unstable cog chance"
