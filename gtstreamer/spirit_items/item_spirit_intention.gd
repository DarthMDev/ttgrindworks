extends ItemSpirit

@export var random_target_chance := 1.0
@export var scaling_stat := 'luck'
@export var scaling_factor := 0.03

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	connect_impure_function(on_round_start, BattleService.s_round_started)
	BattleService.s_cog_missed.connect(on_toon_dodged)

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack and RandomService.randf_channel('true_random') < random_target_chance:
			print('randomizing action: %s' % action.action_name)
			randomize_action(action)

func on_toon_dodged(action: BattleAction) -> void:
	Util.get_player().boost_queue.queue_text("Luck Up!", Color(0.0, 0.602, 0.186))
	Util.get_player().stats[scaling_stat] += scaling_factor

func randomize_action(action: ToonAttack) -> void:
	var prev_targets := action.targets
	var prev_main_target = action.main_target
	var new_target = RandomService.array_pick_random('true_random', BattleService.ongoing_battle.cogs.filter(func(x): return x != action.targets[0]))
	if not action.target_type == BattleAction.ActionTarget.ENEMY:
		action.targets.clear()
		action.reassess_splash_targets(BattleService.ongoing_battle.cogs.find(new_target), BattleService.ongoing_battle)
		if not action.main_target == prev_main_target:
			Util.get_player().boost_queue.queue_text("Spaced out!", Color(0.0, 0.602, 0.186))
	else:
		action.targets = [new_target]
		if not action.targets[0] == prev_targets[0]:
			Util.get_player().boost_queue.queue_text("Spaced out!", Color(0.0, 0.602, 0.186))
	action.special_action_exclude = true
