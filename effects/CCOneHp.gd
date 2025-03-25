# Reduces the player's health to 1
extends CCEffect

class_name CCOneHp

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	if player != null:
		player.stats.hp = 1
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 1
