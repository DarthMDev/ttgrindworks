extends CCEffect

class_name CCTakeJellybeans

var player = Util.get_player()

# Removes a random amount of jellybeans from the player (1-20)
func _trigger(_instance: CCEffectInstance) -> EffectResult:
    if player == null:
        return FAILURE
    var jellybeans = player.stats.money
    randomize()
    var amount = randi_range(1, 20)
    if jellybeans < amount:
        amount = jellybeans
    player.stats.money -= amount
    return SUCCESS


func _can_run() -> bool:
    if player != null and player.stats.hp > 0:
        return true
    if player.stats.money > 0:
        return true
    return false