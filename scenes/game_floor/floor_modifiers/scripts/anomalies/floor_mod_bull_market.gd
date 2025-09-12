extends FloorModifier

## Gives all cogs on the floor 20 percent more health
func modify_floor() -> void:
	game_floor.s_cog_spawned.connect(
		func(cog: Cog):
			cog.health_mod *= 1.2
	)

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Bull Market"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/Volatile_Market.png")

func get_description() -> String:
	return "Cog HP is increased by 20%"
