extends ItemScript

const RANDOM_COG_CHANCE := 0.35

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_start)

func on_round_start(actions: Array[BattleAction]) -> void:
	# Keep track of how many duplicates we've added so far
	var i = 0
	var dups = 0
	var size = actions.size()
	while i < size:
		var action = actions[i]

		print("hello there")

		if action is ToonAttack and RandomService.randf_channel('true_random') < RANDOM_COG_CHANCE:
			print(RandomService.randf_channel('true_random'))
			print('randomizing action: %s' % action.action_name)
			
			var duplicate_action = action.duplicate(true)
			duplicate_action.targets = action.targets.duplicate()
			duplicate_action.main_target = action.main_target
			print(action.targets)
			print(duplicate_action.targets)
			
			randomize_action(duplicate_action)

			# Inject the duplicate action immediately after the current one
			BattleService.ongoing_battle.inject_battle_action(duplicate_action, i + 1)
			i+= 1

		i += 1

	print(actions)
	print(actions.size())


func randomize_action(action: ToonAttack) -> void:
	var prev_targets := action.targets
	var prev_main_target = action.main_target
	if not action.target_type == BattleAction.ActionTarget.ENEMY:
		action.targets.clear()
		action.reassess_splash_targets(RandomService.randi_channel('true_random') % BattleService.ongoing_battle.cogs.size(), BattleService.ongoing_battle)
		if not action.main_target == prev_main_target:
			Util.get_player().boost_queue.queue_text("Duplicate!", Color(0.0, 0.602, 0.186))
	else:
		action.targets = [RandomService.array_pick_random('true_random', BattleService.ongoing_battle.cogs)]
		if not action.targets[0] == prev_targets[0]:
			Util.get_player().boost_queue.queue_text("Duplicate!", Color(0.0, 0.602, 0.186))
	action.special_action_exclude = true
