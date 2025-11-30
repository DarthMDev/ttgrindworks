# this effect will change the current active item to a random one or add a new one if the player has none
extends CCEffect
class_name CCChangePocketPrank

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	var active_item = ItemService.get_random_active_item().duplicate(true)
	active_item.apply_item(player)
	active_item.play_collection_sound()
	return SUCCESS
	
func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	return false