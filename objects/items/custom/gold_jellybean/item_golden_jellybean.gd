extends ItemScriptActive

const PRICE_REDUCTION := 0.75

func use() -> void:
	var world_item := ItemService.get_closest_item()
	
	if not world_item or not world_item.has_node('CollisionShape3D') or item_is_jellybean(world_item.item):
		cancel_use()
		return
	
	
	# Flooring bc this is kinda crazy for getting money money money money
	var bean_reward := floori(world_item.item.get_shop_price() * PRICE_REDUCTION)
	world_item.destroy_item()
	Util.get_player().stats.add_money(bean_reward)

func item_is_jellybean(item : Item) -> bool:
	for _item : Item in ItemService.BEAN_POOL.items:
		if _item.item_name == item.item_name:
			return true
	return false
