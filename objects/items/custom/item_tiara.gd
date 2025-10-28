extends ItemScript


func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func on_battle_start(manager: BattleManager) -> void:
	manager.s_round_started.connect(on_round_start.bind(manager))

func on_round_start(_actions: Array[BattleAction], manager: BattleManager) -> void:
	manager.s_round_started.disconnect(on_round_start)
	manager.s_action_added.connect(on_action_added.bind(manager))
	manager.s_round_ended.connect(on_round_ended.bind(manager))
	
	# Skip Cogs' first turn
	for i in range(manager.round_actions.size() - 1, -1, -1):
		var action := manager.round_actions[i]
		if action.user is Cog and randf() < 0.5:
			manager.round_actions.remove_at(i)
			Util.get_player().boost_queue.queue_text("Cog Turn Skipped!", Color(0.659, 0.801, 0.89))

func on_action_added(action: BattleAction, manager: BattleManager) -> void:
	if action.user is Cog:
		manager.round_actions.erase(action)

func on_round_ended(manager: BattleManager) -> void:
	if manager.s_action_added.is_connected(on_action_added):
		manager.s_action_added.disconnect(on_action_added)

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()
