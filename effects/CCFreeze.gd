# this effect freezes the toon in place (they can still rotate)
extends CCEffectTimed

class_name CCFreeze

func _start(_instance: CCEffectInstanceTimed) -> EffectResult:
	var player = Util.get_player()
	if player:
		player.movement_disabled = true # Disable movement inputs
		player.can_jump = false # Disable jumping
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
		player.can_jump = true # Re-enable jumping
	return true

func _resume() -> void:
	var player = Util.get_player()
	if player:
		player.movement_disabled = true # Reapply movement restriction on resume
		player.can_jump = false # Reapply jump restriction
		
func _pause() -> void:
	var player = Util.get_player()
	if player:
		player.movement_disabled = false # Temporarily allow movement during pause
		player.can_jump = true # Temporarily allow jumping