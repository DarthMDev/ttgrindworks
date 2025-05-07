# this effect removes a single charge from an active item if the player has one
extends CCEffect
class_name CCRemovePocketPrankCharge

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	player.stats.current_active_item.current_charge -= 1
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if player.stats.current_active_item and player.stats.current_active_item.current_charge > 0:
		return true
	return false
