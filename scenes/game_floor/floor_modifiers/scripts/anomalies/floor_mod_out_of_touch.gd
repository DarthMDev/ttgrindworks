extends FloorModifier

## Obscures the player's laff meter for the floor
func modify_floor() -> void:
	if Util.get_player():
		Util.get_player().laff_meter.obscured = true

func clean_up() -> void:
	Util.get_player().laff_meter.obscured = false

func get_mod_quality() -> ModType:
	return ModType.NEGATIVE

func get_mod_name() -> String:
	return "Out of Touch"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/Out_of_Touch.png")

func get_description() -> String:
	return "Obscured Laff meter"
