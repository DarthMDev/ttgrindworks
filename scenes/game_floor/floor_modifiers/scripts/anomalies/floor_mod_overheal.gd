extends FloorModifier

## Boosts the player's max hp for the floor

const BOOST_AMOUNT := 1.2

var raw_boost := 0

func modify_floor() -> void:
	var player := Util.get_player()
	raw_boost = ceili(player.stats.max_hp * BOOST_AMOUNT) - player.stats.max_hp
	player.stats.max_hp += raw_boost

func clean_up() -> void:
	var player := Util.get_player()
	player.stats.max_hp -= raw_boost
	player.stats.hp = mini(player.stats.hp, player.stats.max_hp)

func get_mod_quality() -> ModType:
	return ModType.POSITIVE

func get_mod_name() -> String:
	return "Laff It Up!"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/laff_it_up.png")

func get_icon_offset() -> Vector2:
	return Vector2(11, 5)

func get_description() -> String:
	return "20% increased max Laff"
