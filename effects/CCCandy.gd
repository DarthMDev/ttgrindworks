extends CCEffect

class_name CCCandy

var candy: Item

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	candy = ItemService.get_random_candy()
	candy = candy.duplicate(true)
	candy.apply_item(player)
	candy.play_collection_sound()
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.update_battle_stats()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return (player != null and player.stats.hp > 0)
