# this effect will generate a random doodle and give it to the player
extends CCEffect
class_name CCDoodle


func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()

	# setup a doodle item that will be applied to the player using apply_item 
	var doodle_item : Item = ItemService.get_doodle()
	doodle_item = doodle_item.duplicate(true)
	doodle_item.apply_item(player)
	doodle_item.play_collection_sound()
	
	# save the doodle to the player's save data

	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	return false
