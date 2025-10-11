@tool
extends StatBoost

const BOOST_RANGE := Vector2(0.4, 0.6)
const BOOST_STATS := [
	'damage',
	'defense',
	'accuracy',
]

func apply() -> void:
	stat = BOOST_STATS.pick_random()
	boost = randf_range(BOOST_RANGE.x, BOOST_RANGE.y)

func get_icon() -> Texture2D:
	return GameLoader.load("res://ui_assets/battle/statuses/wheelhouse.png")

func get_status_name() -> String:
	return "Wheelhouse"

func combine(_effect: StatusEffect) -> bool:
	return false
