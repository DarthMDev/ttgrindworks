extends CCEffect

class_name CCJellybean

# random jellybean (3-20)
func _trigger(_instance: CCEffectInstance) -> EffectResult:
    var player = Util.get_player()
    randomize()
    var jellybeans = randi() % 18 + 3
    player.stats.add_money(jellybeans)
    return SUCCESS

func _can_run() -> bool:
    var player = Util.get_player()
    if player == null:
        return false
    return player.stats.hp > 0
