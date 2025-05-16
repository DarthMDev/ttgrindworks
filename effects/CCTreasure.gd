extends CCEffect

class_name CCTreasure

var treasure: Item

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	treasure = ItemService.get_random_treasure()
	treasure = treasure.duplicate()
	treasure.apply_item(player)
	treasure.play_collection_sound()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return (player != null
			and player.stats.hp > 0)
