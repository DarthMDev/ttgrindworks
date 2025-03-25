extends CCEffect

class_name CCRemoveConsumables

var player = Util.get_player()

# removes all battle consumables from the player besides pink slips

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    var items: Array[Item] = player.stats.items
    # Iterate through items to find battle consumables
    # then remove the item and its effects
    for item in items:
        if (item.shop_category_title == "Consumable" and
            item.item_name != "Pink Slip"):
            item.remove_item(player)
    return SUCCESS

func _can_run() -> bool:
    if (player != null and player.stats.hp > 0):
        return true
    if player.stats.items.find(func(item): return item.shop_category_title == "Consumable" and item.item_name != "Pink Slip") != null:
        return true
    return false