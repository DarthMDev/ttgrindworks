extends FloorModifier


func modify_floor() -> void:
	Util.monolitic = true
	Util.force_foreman = 2

func clean_up() -> void:
	Util.monolitic = true
	Util.force_foreman = null


func get_mod_name() -> String:
	return "Annoying Foremen"

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/proxy_add.png")

func get_description() -> String:
	return "All Foremen will have the annoying ability"

func get_mod_quality() -> ModType:
	return ModType.NEUTRAL
