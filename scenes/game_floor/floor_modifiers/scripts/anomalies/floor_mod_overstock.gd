extends FloorModifier

const SALE_MULTIPLIER := 0.5
const FLOOR_TAG := 'shop_overstock'

## Makes one shop item free and puts everything on sale
func modify_floor() -> void:
	if FLOOR_TAG in game_floor.floor_tags:
		game_floor.floor_tags[FLOOR_TAG] += 1.0
	else:
		game_floor.floor_tags[FLOOR_TAG] = 1.0
	
	# Connect to shop spawned signal to modify shop prices
	Globals.s_shop_spawned.connect(on_shop_spawned)
	
func on_shop_spawned(shop: ToonShop) -> void:
	# Find a random item to make free
	var available_items := []
	for i in range(shop.world_items.size()):
		if is_instance_valid(shop.world_items[i]) and not shop.world_items[i].is_queued_for_deletion():
			available_items.append(i)
			
	if available_items.is_empty():
		return
	
	# Pick a random item to make free
	var free_item_index: int = RNG.channel(RNG.ChannelOverstockFreeItem).pick_random(available_items)
	
	# Apply overstock effects to all items
	for i in range(shop.world_items.size()):
		if not is_instance_valid(shop.world_items[i]) or shop.world_items[i].is_queued_for_deletion():
			continue
		
		if i == free_item_index:
			# Make this item free
			shop.stored_prices[i] = 0
			shop.discounted_items[i] = true
		else:
			# Apply sale discount to other items
			var original_price: int = shop.stored_prices[i]
			shop.stored_prices[i] = maxi(0, roundi(original_price * SALE_MULTIPLIER))
			shop.discounted_items[i] = true
	
	
func clean_up() -> void:
	if FLOOR_TAG in game_floor.floor_tags:
		game_floor.floor_tags[FLOOR_TAG] -= 1.0
		if game_floor.floor_tags[FLOOR_TAG] <= 0:
			game_floor.floor_tags.erase(FLOOR_TAG)
			
func get_mod_name() -> String:
	return "Overstock"

func get_mod_quality() -> ModType:
	return ModType.POSITIVE

func get_mod_icon() -> Texture2D:
	return load("res://ui_assets/player_ui/pause/sale.png")

func get_description() -> String:
	return "The shop has one free item and everything else is on sale!"
