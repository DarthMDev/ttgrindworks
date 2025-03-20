extends CCEffect

class_name CCCandy

var candy: Item
var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	candy = ItemService.get_random_candy()
	if player == null:
		return FAILURE
	candy.apply_item(player)
	return SUCCESS

func _can_run() -> bool:
	return (player != null and player.stats.hp > 0)
