extends CCEffectTimed

class_name CCGravity

const GRAVITY_MULTIPLIER := 0.75

# low gravity for 15 seconds

var player = Util.get_player()
var original_gravity
func _trigger(_instance: CCEffectInstance) -> EffectResult:
    
    if player == null:
        return FAILURE
    if player.stats.hp <= 0:
        return FAILURE
    original_gravity = player.gravity
    player.gravity *= GRAVITY_MULTIPLIER
    return SUCCESS

func _can_run() -> bool:
    return (player != null and player.stats.hp > 0)

func _cleanup() -> void:
    player.gravity = original_gravity

