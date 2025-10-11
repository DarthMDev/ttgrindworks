extends FloorModifier

var level_change_vector: Vector2i

## Increases the Cog level min/max for the floor
func modify_floor() -> void:
	if tightened_sec_present():
		level_change_vector = Vector2i(-1, 0)
	else:
		level_change_vector = Vector2(-1, -1)
	game_floor.level_range += level_change_vector

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

func tightened_sec_present() -> bool:
	for modifier in game_floor.floor_variant.anomalies:
		if modifier.resource_path == "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd":
			return true
	return false
