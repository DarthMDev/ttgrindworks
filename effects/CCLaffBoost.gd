extends CCEffect

class_name CCLaffBoost

var player = Util.get_player()

# Increases the player's laff by 1-6

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    randomize()
    var amount = randi_range(1, 6)
    player.stats.max_hp += amount
    return SUCCESS

func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    return false