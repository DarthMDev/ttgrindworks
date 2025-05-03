extends FloorModifier


## Decreases the Cog level min/max for the floor
func modify_floor() -> void:
	game_floor.level_range -= Vector2i(1, 1)

func clean_up() -> void:
	game_floor.level_range += Vector2i(1, 1)

func get_mod_name() -> String:
	return "Faulty Security"

func get_mod_quality() -> ModType:
	return ModType.POSITIVE

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/faulty_security.png")

func get_description() -> String:
	return "Cogs are one level lower"
