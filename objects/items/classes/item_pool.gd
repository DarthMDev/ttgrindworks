@tool
extends Resource
class_name ItemPool

@export var items : Array[Item]

@export_tool_button("Print Item List") var print_action = print_items

func print_items() -> void:
	for i in items.size():
		var item : Item = items[i]
		if item:
			print("%d. %s" % [i + 1, item.item_name])
		else:
			print("%d. null" % (i + 1))

func get_lowest_rarity() -> Item.Rarity:
	var lowest_rating := Item.Rarity.Q7
	for item in items:
		var item_rarity := item.get_true_rarity()
		if item_rarity < lowest_rating:
			lowest_rating = item_rarity
	return lowest_rating
