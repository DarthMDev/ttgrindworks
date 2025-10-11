extends ItemScript

const RANDOM_COG_CHANCE := 0.15

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_start)

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack and randf() < RANDOM_COG_CHANCE:
			print('Randomizing action: %s' % action.action_name)
			randomize_action(action)

func randomize_action(action: ToonAttack) -> void:
	var prev_targets := action.targets
	var prev_main_target = action.main_target
	if not action.target_type == BattleAction.ActionTarget.ENEMY:
		action.targets.clear()
		action.reassess_splash_targets(randi() % BattleService.ongoing_battle.cogs.size(), BattleService.ongoing_battle)
		if not action.main_target == prev_main_target:
			Util.get_player().boost_queue.queue_text("Spaced out!", Color(0.0, 0.602, 0.186))
	else:
		action.targets = [BattleService.ongoing_battle.cogs.pick_random()]
		if not action.targets[0] == prev_targets[0]:
			Util.get_player().boost_queue.queue_text("Spaced out!", Color(0.0, 0.602, 0.186))
	action.special_action_exclude = true
