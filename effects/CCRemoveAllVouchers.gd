extends CCEffect

class_name CCRemoveAllVouchers

var player = Util.get_player()

# Removes all vouchers from the player

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    var items: Array[Item] = player.stats.items
    # Iterate through items to find vouchers
    # then remove the item and its effects
    for item in items:
        if item.item_name == "Gag Voucher":
            item.remove_item(player)
    return SUCCESS

func _can_run() -> bool:
    if (player != null and player.stats.hp > 0):
        return true
    if player.stats.items.find(func(item): return item.item_name == "Gag Voucher") != null:
        return true
    return false