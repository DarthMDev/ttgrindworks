extends ItemScript

const PER_FLOOR_BOOST := 0.3

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()


func setup() -> void:
	Util.s_floor_started.connect(on_floor_start)

func on_floor_start(_glfoor: GameFloor = null) -> void:
	Util.get_player().stats.stranger_chance += PER_FLOOR_BOOST
