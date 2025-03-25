extends CCEffect

class_name CCRemoveRandomAccessory

var player = Util.get_player()

# Removes a random accessory from the player

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    var items: Array[Item] = player.stats.items
    # Iterate through items to find accessories
    # then remove the item and its effects
    var accessories: Array[Item] = []
    for item in items:
        if item.slot in [Item.ItemSlot.HAT, Item.ItemSlot.GLASSES, Item.ItemSlot.BACKPACK]:
            accessories.append(item)
    var accessory = accessories[randi() % accessories.size()]
    accessory.remove_item(player)
    return SUCCESS

func _can_run() -> bool:
    if (player != null and player.stats.hp > 0):
        return true
    if player.stats.items.find(func(item): return item.slot in [Item.ItemSlot.HAT, Item.ItemSlot.GLASSES, Item.ItemSlot.BACKPACK]) != null:
        return true
    return false