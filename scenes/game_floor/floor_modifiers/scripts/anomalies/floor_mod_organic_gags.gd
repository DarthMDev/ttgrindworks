extends FloorModifier

const BOOST_AMT := 0.1

func modify_floor() -> void:
	Util.get_player().stats.damage += BOOST_AMT

func clean_up() -> void:
	Util.get_player().stats.damage -= BOOST_AMT


func get_mod_name() -> String:
	return "Organic Gags"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/organic_gags.png")

func get_description() -> String:
	return "+10% damage for the floor!"

func get_mod_quality() -> ModType:
	return ModType.POSITIVE
