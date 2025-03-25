extends CCEffect
class_name CCInstaSadness

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	player.stats.hp = 0
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0