extends ItemScript

const HP_BOOST := 4

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	Util.s_floor_started.connect(_on_floor_started)

func get_hp_boost() -> int:
	return HP_BOOST + Util.get_player().stats.laff_boost_boost

func _on_floor_started(_game_floor: GameFloor) -> void:
	await Task.delay(0.5)
	Util.get_player().stats.max_hp += get_hp_boost()
	Util.get_player().stats.hp += get_hp_boost()
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/toonup/sparkly.ogg"), 2.0)
	Util.do_3d_text(Util.get_player(), "+%s" % get_hp_boost(), Color.GREEN, Color.DARK_GREEN)
