# this sets player's current active item to be null if not already
extends CCEffect
class_name CCRemovePocketPrank

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	player.stats.current_active_item = null
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if player.stats.current_active_item:
		return true
	return false
