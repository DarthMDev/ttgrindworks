extends FloorModifier

const PRICE_HIKE := 0.25
const FLOOR_TAG := 'shop_inflation'

## Makes shop prices [price hike] percent higher
func modify_floor() -> void:
	if FLOOR_TAG in game_floor.floor_tags:
		game_floor.floor_tags[FLOOR_TAG] += PRICE_HIKE
	else:
		game_floor.floor_tags[FLOOR_TAG] = 1.0 + PRICE_HIKE

func clean_up() ->void:
	game_floor.floor_tags[FLOOR_TAG] -= PRICE_HIKE

func get_mod_name() -> String:
	return "Inflation"

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/inflation.png")

func get_description() -> String:
	return "Shop prices are 25% higher"
