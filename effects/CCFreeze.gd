# this effect freezes the toon in place (they can still rotate)
extends CCEffectTimed

class_name CCFreeze

func _start(_instance: CCEffectInstanceTimed) -> EffectResult:
	var player = Util.get_player()
	if player:
		player.movement_disabled = true # Disable movement inputs
	return RUNNING

func _should_be_running() -> bool:
	var player = Util.get_player()
	if (player != null and player.stats.hp > 0):
		return true
	if not CrowdControl.is_paused():
		return true
	return false

func _stop(_instance: CCEffectInstanceTimed, _force := false) -> bool:
	var player = Util.get_player()
	if player:
		player.movement_disabled = false # Re-enable movement inputs
	return true

func _resume() -> void:
	var player = Util.get_player()
	if player:
		player.movement_disabled = true # Reapply movement restriction on resume

func _pause() -> void:
	var player = Util.get_player()
	if player:
		player.movement_disabled = false # Temporarily allow movement during pause
