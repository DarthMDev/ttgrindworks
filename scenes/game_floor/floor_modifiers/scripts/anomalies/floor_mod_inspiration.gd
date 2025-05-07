extends FloorModifier

const BOOST_AMT := 0.2
const BOOST_STATS: Array[String] = ['damage', 'defense', 'evasiveness', 'luck', 'speed', 'hp']
var multiplier := StatMultiplier.new()

func modify_floor() -> void:
	multiplier.stat = get_lowest_stat()
	multiplier.additive = true
	multiplier.amount = BOOST_AMT
	Util.get_player().stats.multipliers.append(multiplier)

func get_lowest_stat() -> String:
	var stats := Util.get_player().stats
	var current_stats := BOOST_STATS.map(func(stat): return stats.get_stat(stat))
	return BOOST_STATS[current_stats.find(current_stats.min())]

func clean_up() -> void:
	Util.get_player().stats.multipliers.erase(multiplier)

func get_mod_name() -> String:
	return "Inspiration"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/inspiration.png")

func get_description() -> String:
	return "Increases your lowest stat by 20% for this floor"

## Override this for other objects to tell what type of mod it is
func get_mod_quality() -> ModType:
	return ModType.POSITIVE
