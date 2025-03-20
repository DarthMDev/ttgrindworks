extends CCEffect

class_name CCFire

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	if player == null:
		return FAILURE
	player.stats.pink_slips += 1
		
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0
