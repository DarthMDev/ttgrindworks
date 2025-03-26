extends CCEffect

class_name CCDamage
# take 1 - 20% damage
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	var player = Util.get_player()
	if player != null:
		var percentage = randf_range(1, 20) / 100
		if player.stats.max_hp * percentage < 1:
			player.stats.hp -= 1
		else:
			player.stats.hp -= player.stats.max_hp * percentage
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0
