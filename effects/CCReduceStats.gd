extends CCEffect

class_name CCReduceStats

var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	
	if player == null:
		return FAILURE
	randomize()
	# chose a random stat to take away 10%
	var list_of_stats = ["damage", "defense", "evasiveness", "speed"]
	var stat = list_of_stats[randi_range(0, list_of_stats.size() - 1)]
	player.stats[stat] -= player.stats[stat] * 0.1
	return SUCCESS

func _can_run() -> bool:
	return (player != null and player.stats.hp > 0)
