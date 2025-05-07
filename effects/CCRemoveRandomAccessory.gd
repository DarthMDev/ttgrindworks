extends CCEffect

class_name CCRemoveRandomAccessory

# Removes a random accessory from the player

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	var items: Array[Item] = player.stats.items
	# Iterate through items to find accessories
	# then remove the item and its effects
	var accessories: Array[Item] = []
	for item in items:
		if item is ItemAccessory:
			accessories.append(item)
	if accessories.size() > 0:
		var random_index = randi() % accessories.size()
		var item = accessories[random_index]
		item.remove_item(player)
		return SUCCESS
	return FAILURE
		

func _can_run() -> bool:
	var player = Util.get_player()
	if (player != null and player.stats.hp > 0):
		return true
	for item in player.stats.items:
		if item is ItemAccessory:
			return true
	return false
