extends CCEffect

class_name CCJellybean


func _trigger(_instance: CCEffectInstance) -> EffectResult:
    var player = Util.get_player()
    var jellybean = ItemService.get_random_jellybean()
    jellybean.apply_item(player)
    return SUCCESS

func _can_run() -> bool:
    var player = Util.get_player()
    if player == null:
        return false
    return player.stats.hp > 0
