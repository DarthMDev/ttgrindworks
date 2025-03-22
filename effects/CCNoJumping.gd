extends CCEffectTimed

class_name CCNoJumping

var player = Util.get_player()

# Prevents the player from jumping

func _trigger(_instance: CCEffectInstance) -> EffectResult:
    if player == null:
        return FAILURE
    player.jump_enabled = false
    return SUCCESS


func _can_run() -> bool:
    return (player != null and player.stats.hp > 0)

func _cleanup() -> void:
    player.jump_enabled = true

func _resume() -> void:
    player.jump_enabled = false

func _pause() -> void:
    player.jump_enabled = true