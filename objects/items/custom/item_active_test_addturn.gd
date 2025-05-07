extends ItemScriptActive

func use() -> void:
	super()
	var manager := BattleService.ongoing_battle
	if manager is not BattleManager:
		return
		
	manager.battle_stats[Util.get_player()].turns += 1
	manager.battle_ui.refresh_turns()
