extends CCEffect

class_name CCFire

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	player.stats.pink_slips += 1
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.update_battle_stats()
	return SUCCESS

func _can_run() -> bool:
	return Util.get_player() != null and Util.get_player().stats.hp > 0
