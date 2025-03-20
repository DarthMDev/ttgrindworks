extends CCEffect

class_name CCReduceMaxLaff

var player = Util.get_player()

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	
	if player == null:
		return FAILURE
	randomize()
	player.stats.max_hp -= randi_range(1, 6)
	return SUCCESS

func _can_run() -> bool:
	return (player != null and player.stats.hp > 0 
			and player.stats.max_hp > 30)
