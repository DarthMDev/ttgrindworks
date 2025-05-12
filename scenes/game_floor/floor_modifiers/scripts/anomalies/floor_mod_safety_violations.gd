extends FloorModifier


func modify_floor() -> void:
	game_floor.floor_tags['extra_hazard_damage'] = true

func clean_up() -> void:
	game_floor.floor_tags['extra_hazard_damage'] = false

func get_mod_name() -> String:
	return "Safety Violations"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/safety_violations.png")

func get_description() -> String:
	return "Obstacles are 25% more dangerous"

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE
