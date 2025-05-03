extends ItemScriptActive

const SUPER_CHANCE := 0.1
var CANDY_POOL : ItemPool
var SUPER_CANDY_POOL : ItemPool


func _init() -> void:
	CANDY_POOL = GameLoader.load("res://objects/items/pools/candies.tres")
	SUPER_CANDY_POOL = GameLoader.load("res://objects/items/pools/candies.tres")

func use() -> void:
	var player := Util.get_player()
	var use_pool : ItemPool
	if RandomService.randf_channel('gumball_machine_rolls') < SUPER_CHANCE:
		use_pool = SUPER_CANDY_POOL
	else:
		use_pool = CANDY_POOL
	
	var item : Item = RandomService.array_pick_random('gumball_machine_rolls', use_pool.items)
	item.apply_item(player)
	item.play_collection_sound()
	var ui := ItemService.display_item(item)
	ui.node_viewer.node.setup(item)
