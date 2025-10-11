extends FloorModifier

## Gives all cogs on the floor (that are grunt cogs) a random 80% to 120% HP
func modify_floor() -> void:
	game_floor.s_cog_spawned.connect(
		func(cog: Cog):
			var health_mod := RNG.channel(RNG.ChannelToughCrowdMod).randf_range(0.8, 1.2)
			print('Volatile Market - Applying health mod: %s' % health_mod)
			cog.health_mod *= health_mod
	)

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL

func get_mod_name() -> String:
	return "Volatile Market"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/Volatile_Market.png")

func get_description() -> String:
	return "Cog HP varies"
