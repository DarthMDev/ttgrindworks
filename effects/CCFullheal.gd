extends CCEffect

class_name CCFullheal

var player = Util.get_player()

# Fully heals the player

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    player.stats.hp = player.stats.max_hp
    return SUCCESS

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    if player.stats.hp < player.stats.max_hp:
        return true
    return false