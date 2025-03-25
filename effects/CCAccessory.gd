extends CCEffect

class_name CCAccessory

var accessory: ItemAccessory
# Gives the toon a random accessory
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	accessory = ItemService.get_random_accessory()
	accessory.apply_item(player)        
	accessory.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0
