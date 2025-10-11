extends ItemScriptActive

const RANGE := Vector2(0.5, 1.5)

func use() -> void:
	AudioManager.play_snippet(load("res://audio/sfx/battle/cogs/attacks/SA_audit.ogg"), 0.0, 1.16)
	var cogs := BattleService.ongoing_battle.cogs
	var cog_panels: Control = BattleService.ongoing_battle.battle_ui.cog_panels
	for cog in BattleService.ongoing_battle.cogs:
		var ratio := RNG.channel(RNG.ChannelCalculatorHPMods).randf_range(RANGE.x, RANGE.y)
		var original_hp := cog.stats.hp
		cog.stats.max_hp = int(cog.stats.max_hp * ratio)
		cog.stats.hp = int(original_hp * ratio)
		cog_panels.get_child(cogs.find(cog)).set_cog(cog)
	
	Util.get_player().boost_queue.queue_text("Cog HP Scrambled!", Color.AQUA)
