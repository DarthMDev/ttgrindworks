@tool
extends Resource
class_name ItemPool

const ITEM_ARRAY := GameLoader.FILE_ARRAY_HINT_PREFIX + '*.tres'
@export_custom(GameLoader.FILE_ARRAY, ITEM_ARRAY) var items: PackedStringArray

@export var low_roll_override: Item.Rarity = Item.Rarity.NIL

@export_tool_button("Print Item List") var print_action = print_items
@export_tool_button("Tally Star Ratings") var tally_action = tally_qualities
@export_tool_button("Get Lowest Rarity") var print_rarity = print_rarity_minimum

func add_items(paths: Array[String]):
	var new_items: Array[String] = paths.filter(
		func(item_path: String) -> bool:
			return item_path not in items
	)
	GameLoader.queue(GameLoader.Phase.GAME_START, new_items)
	items.append_array(PackedStringArray(new_items))

func print_items() -> void:
	for i in items.size():
		var item: Item = load(items[i])
		if item:
			print("%d. %s" % [i + 1, item.item_name])
		else:
			print("%d. null" % (i + 1))

func tally_qualities() -> void:
	var qualities: Dictionary[Item.QualitoonRating, int] = {
		Item.QualitoonRating.Q1: 0,
		Item.QualitoonRating.Q2: 0,
		Item.QualitoonRating.Q3: 0,
		Item.QualitoonRating.Q4: 0,
		Item.QualitoonRating.Q5: 0,
	}
	
	for i in items.size():
		var item: Item = load(items[i])
		if item:
			qualities[item.qualitoon] += 1
	
	for key in qualities:
		print("%d Star Items: %d" % [key as int + 1, qualities[key]])

func print_rarity_minimum() -> void:
	print(str(get_lowest_rarity()))

func get_lowest_rarity() -> Item.Rarity:
	var lowest_rating := Item.Rarity.Q7
	for item_path in items:
		var item: Item = load(item_path)
		var item_rarity := get_true_item_rarity(item)
		if item_rarity < lowest_rating:
			lowest_rating = item_rarity
			print("Lower rarity discovered: %s" % item.item_name)
	return lowest_rating

func get_true_item_rarity(item: Item) -> Item.Rarity:
	if not item.rarity == Item.Rarity.NIL:
		return item.rarity
	return Item.QualityToRarity[item.qualitoon]

func _iter_init(iter_state: Array) -> bool:
	iter_state[0] = 0
	return iter_state[0] < items.size()
	
func _iter_next(iter_state: Array) -> bool:
	iter_state[0] += 1
	return iter_state[0] < items.size()
	
func _iter_get(index: Variant) -> Item:
	return load(items[index])

func make_item_array() -> Array[Item]:
	var array: Array[Item]
	for item in self:
		array.append(item)
	return array

func size() -> int:
	return items.size()
