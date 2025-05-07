# this effects randomizes the accessories of the player 
# it will remove all the current accessories and add a new random one
extends CCEffect
class_name CCRandomizeAccessories

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	if player != null:
		for item in player.stats.items:
			if item is ItemAccessory:
				item.remove_item(player)
				var new_item = ItemService.get_random_accessory().duplicate()
				new_item.apply_item(player)
				new_item.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	# make sure the player has at least one accessory
	if player != null and player.stats.hp > 0:
		for item in player.stats.items:
			if item is ItemAccessory:
				return true
	return false
