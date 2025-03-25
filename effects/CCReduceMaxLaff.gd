extends CCEffect

class_name CCReduceMaxLaff

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	randomize()
	player.stats.max_hp -= randi_range(1, 6)
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	return (player != null and player.stats.hp > 0 
			and player.stats.max_hp > 30)
