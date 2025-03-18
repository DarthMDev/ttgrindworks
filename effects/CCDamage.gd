extends CCEffect

class_name CCDamage
# take 1 - 25 damage
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	var player = Util.get_player()
	if player != null:
		player.stats.hp -= randi() % 25 + 1
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null
