extends CCEffectTimed

class_name CCNoJumping

# Prevents the player from jumping

func _start(_instance: CCEffectInstanceTimed) -> EffectResult:
    var player = Util.get_player()
    player.jump_enabled = false
    return RUNNING

func _should_be_running() -> bool:
    var player = Util.get_player()
    if (player != null and player.stats.hp > 0):
        return true
    if not Util.get_tree().paused:
        return true
    return false

func _stop(_instance: CCEffectInstanceTimed, _force := false) -> bool:
    var player = Util.get_player()
    player.jump_enabled = true
    return true

func _resume() -> void:
    var player = Util.get_player()
    player.jump_enabled = false

func _pause() -> void:
    var player = Util.get_player()
    player.jump_enabled = true
