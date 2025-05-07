# this effect freezes the toon in place (they can still rotate)
extends CCEffectTimed

class_name CCFreeze

var original_speed;
func _start(_instance: CCEffectInstanceTimed) -> EffectResult:
	var player = Util.get_player()
	original_speed = player.stats.speed
	player.stats.speed = 0
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
	player.stats.speed = original_speed
	return true

func _resume() -> void:
	var player = Util.get_player()
	player.stats.speed = 0

func _pause() -> void:
	var player = Util.get_player()
	player.stats.speed = original_speed
