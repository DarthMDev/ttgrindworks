extends FloorModifier

var level_change_vector: Vector2i

## Increases the Cog level min/max for the floor
func modify_floor() -> void:
	if faulty_sec_present():
		level_change_vector = Vector2i(0, 1)
	else:
		level_change_vector = Vector2(1, 1)
	game_floor.level_range += level_change_vector
	

func clean_up() -> void:
	game_floor.level_range -= level_change_vector

func get_mod_name() -> String:
	return "Tightened Security"

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/tightened_security.png")

func get_description() -> String:
	return "Cogs are one level higher"

func faulty_sec_present() -> bool:
	for modifier in game_floor.floor_variant.anomalies:
		if modifier.resource_path == "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_down.gd":
			return true
	return false
