@tool
extends Resource
class_name ItemPool

@export var items: Array[Item]

@export_tool_button("Print Item List") var print_action = print_items
@export_tool_button("Get Lowest Rarity") var print_rarity = print_rarity_minimum

func print_items() -> void:
	for i in items.size():
		var item: Item = items[i]
		if item:
			print("%d. %s" % [i + 1, item.item_name])
		else:
			print("%d. null" % (i + 1))

func print_rarity_minimum() -> void:
	print(str(get_lowest_rarity()))

func get_lowest_rarity() -> Item.Rarity:
	var lowest_rating := Item.Rarity.Q7
	for item in items:
		var item_rarity := get_true_item_rarity(item)
		if item_rarity < lowest_rating:
			lowest_rating = item_rarity
			print("Lower rarity discovered: %s" % item.item_name)
	return lowest_rating

func get_true_item_rarity(item: Item) -> Item.Rarity:
	if not item.rarity == Item.Rarity.NIL:
		return item.rarity
	return Item.QualityToRarity[item.qualitoon]
