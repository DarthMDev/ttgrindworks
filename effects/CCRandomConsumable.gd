extends CCEffect

class_name CCRandomConsumable

var player = Util.get_player()

# Gives the toon a random consumable besides pink slips

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    if player == null:
        return FAILURE
    var consumable = ItemService.get_random_consumable()
    consumable.apply_item(player)        
    
    return SUCCESS

func _can_run() -> bool:
    return player != null and player.stats.hp > 0