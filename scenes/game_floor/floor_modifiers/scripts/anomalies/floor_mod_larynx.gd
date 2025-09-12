extends FloorModifier


func modify_floor() -> void:
	Util.monolitic = true
	Util.force_foreman = 8

func clean_up() -> void:
	Util.monolitic = false
	Util.force_foreman = null


func get_mod_name() -> String:
	return "Decibel Disaster"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/larynx.png")

func get_description() -> String:
	return "All Foremen will have the larynx ability"

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL
