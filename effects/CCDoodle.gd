# this effect will generate a random doodle and give it to the player
extends CCEffect
class_name CCDoodle


func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()

	var doodle = ItemService.get_doodle().duplicate()
	doodle.apply_item(player)
	doodle.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	return false