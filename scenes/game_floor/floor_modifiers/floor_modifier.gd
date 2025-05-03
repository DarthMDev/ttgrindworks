extends Node
class_name FloorModifier

enum ModType {
	POSITIVE,
	NEUTRAL,
	NEGATIVE
}

const QUALITY_COLORS : Dictionary[ModType, Array] = {
	ModType.POSITIVE : [Color.GREEN, Color.DARK_GREEN],
	ModType.NEUTRAL : [Color(0.067, 0.42, 1.0), Color("001f8a")],
	ModType.NEGATIVE : [Color.RED, Color.DARK_RED],
}

var game_floor: GameFloor
var text_color : Color:
	get: return QUALITY_COLORS[get_mod_quality()][0]
var outline_color : Color:
	get: return QUALITY_COLORS[get_mod_quality()][1]

## Do not override.
## Unless you really want to :)
func initialize(new_floor: GameFloor) -> void:
	game_floor = new_floor
	game_floor.s_floor_ended.connect(clean_up)
	modify_floor()

## Override this function to perform actions to a floor
func modify_floor() -> void:
	pass

## Override this function to run a cleanup at the end of a floor 
func clean_up() -> void:
	pass

## Override this to name the node properly
func get_mod_name() -> String:
	return "FloorMod"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/laff_it_up.png")

func get_icon_offset() -> Vector2:
	return Vector2(9, 9)

func get_description() -> String:
	return "Anomaly description"

## Override this for other objects to tell what type of mod it is
func get_mod_quality() -> ModType:
	return ModType.NEUTRAL
