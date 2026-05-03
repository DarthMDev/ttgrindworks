extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'

const MOTORCYCLE_BOOTS := "res://objects/items/resources/accessories/shoes/motorcycle_boots.tres"
const ACCESSORIES := "res://objects/items/pools/accessories.tres"

func on_collect(_item: Item, _object: Node3D) -> void:
	var boots: ItemShoe = load(MOTORCYCLE_BOOTS)
	var player := Util.get_player()
	if not boots in player.character.starting_items:
		player.character.starting_items.append(boots)
		ItemService.seen_item(boots)
	elif player.character.character_id == PlayerCharacter.Character.MYSTERY:
		var new_item: Item 
		while not new_item or new_item is ItemShoe:
			new_item = ItemService.get_random_item(ItemService.pool_from_path(ACCESSORIES))
		player.character.starting_items.append(new_item)
		ItemService.seen_item(new_item)
