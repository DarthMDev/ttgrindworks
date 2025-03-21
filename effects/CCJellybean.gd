extends CCEffect

class_name CCJellybean

var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    
    if player == null:
        return FAILURE
    var jellybean = ItemService.get_random_jellybean()
    jellybean.apply_item(player)
    return SUCCESS

func _can_run() -> bool:
    if player == null:
        return false
    return player.stats.hp > 0