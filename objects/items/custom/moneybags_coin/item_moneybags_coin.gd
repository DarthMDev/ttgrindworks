extends ItemScriptActive


const COINSPILL := "res://objects/battle/effects/coin/coinspill.tscn"
const CHA_CHING := "res://audio/sfx/items/cash_register.ogg"

func use() -> void:
	var manager := BattleService.ongoing_battle
	var roll := do_roll()
	if roll:
		manager.battle_stats[Util.get_player()].turns *= 2
		Util.get_player().boost_queue.queue_text("Heads!", Color(0.487, 1.0, 0.43, 1.0))
	else:
		manager.battle_stats[Util.get_player()].turns = 1
		Util.get_player().boost_queue.queue_text("Tails!", Color(1.0, 0.287, 0.225))
		cancel_out_gags()
	manager.battle_ui.refresh_turns()
	if not manager.s_round_started.is_connected(reset_moves):
		manager.s_round_started.connect(reset_moves, CONNECT_ONE_SHOT)
	
	var coinspill: Node3D = load(COINSPILL).instantiate()
	Util.get_player().add_child(coinspill)
	Task.delay(1.5).connect(coinspill.queue_free)
	AudioManager.play_sound(load(CHA_CHING))

func do_roll() -> bool:
	var roll := RNG.channel(RNG.ChannelMoneybagsCoin).randf()
	return roll < Util.get_player().stats.get_luck_weighted_chance(0.5, 0.75, 2.0)

func reset_moves(_battle) -> void:
	var manager := BattleService.ongoing_battle
	var player := Util.get_player()
	manager.battle_stats[player].turns = player.stats.turns
	manager.battle_ui.refresh_turns()

func cancel_out_gags() -> void:
	var manager := BattleService.ongoing_battle
	var ui := manager.battle_ui
	for gag in ui.selected_gags.duplicate():
		ui.cancel_gag(ui.selected_gags.find(gag))
