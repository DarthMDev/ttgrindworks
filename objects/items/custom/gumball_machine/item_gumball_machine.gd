extends ItemScriptActive

const SUPER_CHANCE := 0.15
var CANDY_POOL: ItemPool
var SUPER_CANDY_POOL: ItemPool


func _init() -> void:
	CANDY_POOL = GameLoader.load("res://objects/items/pools/candies.tres")
	SUPER_CANDY_POOL = GameLoader.load("res://objects/items/pools/super_candies.tres")

func use() -> void:
	var player := Util.get_player()
	var use_pool: ItemPool
	if RNG.channel(RNG.ChannelGumballMachineRolls).randf() < Util.get_relevant_player_stats().get_luck_weighted_chance(SUPER_CHANCE, 0.3, 2.0):
		use_pool = ItemService.get_centralized_pool(SUPER_CANDY_POOL)
	else:
		use_pool = ItemService.get_centralized_pool(CANDY_POOL)
	
	var _item: Item = RNG.channel(RNG.ChannelGumballMachineRolls).pick_random(use_pool.make_item_array())
	_item.apply_item(player)
	_item.play_collection_sound()
	var ui := ItemService.display_item(_item)
	ui.node_viewer.node.setup(_item)
