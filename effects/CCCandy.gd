extends CCEffect

class_name CCCandy

var candy: Item

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	candy = ItemService.get_random_candy()
	candy.apply_item(player)
	candy.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return (player != null and player.stats.hp > 0)
