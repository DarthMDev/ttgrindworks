extends Sprite3D

static var TREASURE_LIMIT := 7

@onready var treasure_pool: ItemPool = GameLoader.load("res://objects/items/pools/treasures.tres")
var item: Item
var heal_perc := 0.1

func setup(res: Item) -> void:
	item = res
	if RNG.channel(RNG.ChannelTreasureRerollChance).randi() % TREASURE_LIMIT <= get_available_treasures():
		item.reroll()
	elif Util.get_player().revives_are_hp and Util.get_player().stats.extra_lives >= ItemService.REVIVE_GOAL:
		item.reroll()

	if Util.get_player().revives_are_hp:
		oldman_setup()
		return

	if item.arbitrary_data.has('heal_perc'):
		item.big_description = "Heals " + str(item.arbitrary_data['heal_perc']) + "% of your max laff."
		heal_perc = float(item.arbitrary_data['heal_perc']) / 100.0
	if item.arbitrary_data.has('texture'):
		texture = item.arbitrary_data['texture']

func collect() -> void:
	if is_instance_valid(Util.get_player()):
		Util.get_player().quick_heal(maxi(roundi(float(get_heal_value()) * 0.333), 1))
		Util.get_player().stats.treasures[get_treasure_index()] += 1

func modify(ui_asset: Sprite3D) -> void:
	ui_asset.texture = texture

func get_heal_value() -> int:
	if not Util.get_player() or not Util.get_player().stats:
		return 5
	return ceili(Util.get_player().stats.max_hp * heal_perc)

func get_treasure_index() -> int:
	var index := 0
	for _item in treasure_pool:
		if _item.item_name == item.item_name:
			return index
		index += 1
	return -1

func get_available_treasures() -> int:
	var treasure_count := 0
	for key in Util.get_player().stats.treasures.keys():
		treasure_count += Util.get_player().stats.treasures[key]
	for itm in ItemService.items_in_play:
		if item_is_treasure(itm) and not item == itm:
			treasure_count += 1
	return treasure_count

func item_is_treasure(itm: Item) -> bool:
	for treasure: Item in treasure_pool:
		if itm.item_name == treasure.item_name:
			return true
	return false

func oldman_setup() -> void:
	item.stats_add['max_hp'] = 1
	item.big_description = "Grants +%d revives" % get_oldman_revive_count(item)
	if item.arbitrary_data.has('texture'):
		texture = item.arbitrary_data['texture']

func get_oldman_revive_count(res: Item) -> int:
	return res.arbitrary_data['heal_perc'] / 10
