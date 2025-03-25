extends CCEffect

class_name CCTreasure

var treasure: Item
var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	treasure = ItemService.get_random_roll_fail_item()
	treasure.apply_item(player)
	return SUCCESS

func _can_run() -> bool:
	return (player != null and player.stats.hp != player.stats.max_hp
			and player.stats.hp > 0)
