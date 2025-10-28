extends ItemScriptActive

const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")

func use() -> void:
	var battle_manager: BattleManager = BattleService.ongoing_battle
	
	if is_instance_valid(battle_manager):
		Util.get_player().boost_queue.queue_text("Guaranteed Crits!", Color.GREEN)
		battle_manager.s_round_started.connect(guarantee_crits, CONNECT_ONE_SHOT)

func guarantee_crits(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack:
			if not is_equal_approx(action.crit_chance_mod, 0.0):
				action.crit_chance_mod = Globals.CRIT_MOD_GUARANTEE
