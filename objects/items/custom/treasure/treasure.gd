extends Sprite3D

@onready var treasure_pool : ItemPool = GameLoader.load("res://objects/items/pools/treasures.tres")
var item : Resource
var heal_perc := 0.1

func setup(res : Item) -> void:
	item = res
	if item.arbitrary_data.has('heal_perc'):
		item.big_description = "Heals " + str(item.arbitrary_data['heal_perc']) + "% of your max laff."
		heal_perc = float(item.arbitrary_data['heal_perc']) / 100.0
	if item.arbitrary_data.has('texture'):
		texture = item.arbitrary_data['texture']

func collect() -> void:
	if is_instance_valid(Util.get_player()):
		Util.get_player().quick_heal(get_heal_value() / 4)
		Util.get_player().stats.treasures[get_treasure_index()] += 1

func modify(ui_asset : Sprite3D) -> void:
	ui_asset.texture = texture

func get_heal_value() -> int:
	if not Util.get_player() or not Util.get_player().stats:
		return 5
	return ceili(Util.get_player().stats.max_hp * heal_perc)

func get_treasure_index() -> int:
	for _item in treasure_pool.items:
		if _item.item_name == item.item_name:
			return treasure_pool.items.find(_item)
	return -1
