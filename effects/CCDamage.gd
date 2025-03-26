extends CCEffect

class_name CCDamage
# take 1 - 20% damage
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	var player = Util.get_player()
	if player != null:
		var percentage = rand_range(1, 20) / 100
		player.stats.hp -= player.stats.hp * percentage
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0
