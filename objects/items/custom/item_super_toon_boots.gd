extends ItemScript


func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(manager: BattleManager) -> void:
	await get_tree().process_frame
	manager.battle_stats[Util.get_player()].turns += 1
	manager.s_round_started.connect(reset_moves.bind(manager), CONNECT_ONE_SHOT)
	manager.battle_ui.refresh_turns()

func reset_moves(_actions, manager: BattleManager) -> void:
	manager.battle_stats[Util.get_player()].turns -= 1
	manager.battle_ui.refresh_turns()
