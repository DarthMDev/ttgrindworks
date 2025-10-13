extends ItemScriptActive


func use() -> void:
	AudioManager.play_sound(load('res://audio/sfx/ui/GUI_stickerbook_open.ogg'))
	BattleService.ongoing_battle.s_round_started.connect(on_round_start, CONNECT_ONE_SHOT)
	for cog in BattleService.ongoing_battle.cogs:
		apply_stat_boost(cog)
	BattleService.ongoing_battle.battle_ui.cog_panels.reset(0)
	BattleService.ongoing_battle.battle_ui.cog_panels.assign_cogs(BattleService.ongoing_battle.cogs)
	Util.get_player().boost_queue.queue_text("Cog turns skipped!", Color(0.659, 0.801, 0.89))

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions.duplicate(true):
		if action is CogAttack:
			BattleService.ongoing_battle.round_actions.erase(action)
	for cog in BattleService.ongoing_battle.cogs:
		if not cog in BattleService.ongoing_battle.has_moved:
			BattleService.ongoing_battle.has_moved.append(cog)

func apply_stat_boost(cog: Cog) -> void:
	var stat_boost: StatBoost = load('res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres').duplicate(true)
	stat_boost.rounds = -1
	stat_boost.stat = 'damage'
	stat_boost.boost = 0.2
	stat_boost.quality = StatusEffect.EffectQuality.POSITIVE
	stat_boost.target = cog
	BattleService.ongoing_battle.add_status_effect(stat_boost)
