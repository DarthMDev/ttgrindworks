extends CCEffect

class_name CCReduceStats

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	randomize()
	# chose a random stat to take away 10%
	var list_of_stats = ["damage", "defense", "evasiveness", "speed"]
	var stat = list_of_stats[randi_range(0, list_of_stats.size() - 1)]
	player.stats[stat] -= player.stats[stat] * 0.1
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.update_battle_stats()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return (player != null and player.stats.hp > 0)
