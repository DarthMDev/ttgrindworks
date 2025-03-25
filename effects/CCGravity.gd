extends CCEffectTimed

class_name CCGravity

const GRAVITY_MULTIPLIER := 0.75

# low gravity for 15 seconds

var original_gravity
func _start(_instance: CCEffectInstanceTimed) -> EffectResult:
    var player = Util.get_player()
    original_gravity = player.gravity
    player.gravity *= GRAVITY_MULTIPLIER
    return RUNNING

func _stop(_instance: CCEffectInstanceTimed, _force := false) -> bool:
    var player = Util.get_player()
    player.gravity = original_gravity
    return true

func _should_be_running() -> bool:
    var player = Util.get_player()
    if (player != null and player.stats.hp > 0):
        return true
    if not Util.get_tree().paused:
        return true
    return false

func _resume() -> void:
    var player = Util.get_player()
    player.gravity *= GRAVITY_MULTIPLIER

func _pause() -> void:
    var player = Util.get_player()
    player.gravity = original_gravity
