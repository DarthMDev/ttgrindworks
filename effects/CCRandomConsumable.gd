extends CCEffect

class_name CCRandomConsumable

# Gives the toon a random consumable besides pink slips

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	var consumable = ItemService.get_random_consumable()
	consumable = consumable.duplicate(true)
	consumable.apply_item(player)        
	consumable.play_collection_sound()
	# update the battle stats too if we are in a battle
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.update_battle_stats()
		
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return player != null and player.stats.hp > 0
