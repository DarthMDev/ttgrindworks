extends ItemScript

var swapped_actions : Array[ToonAttack] = []


func on_collect(_item : Item, _model : Node3D) -> void:
	setup()

func on_load(_item : Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(battle : BattleManager) -> void:
	battle.s_participant_will_die.connect(participant_will_die)
	battle.s_action_started.connect(on_action_started)
	battle.s_battle_ended.connect(on_battle_end)

func participant_will_die(who : Node3D) -> void:
	if who is Cog:
		cog_will_die(who)

func on_battle_end() -> void:
	swapped_actions.clear()

func cog_will_die(cog : Cog) -> void:
	var battle := BattleService.ongoing_battle
	for action : BattleAction in battle.round_actions:
		if action is ToonAttack:
			if check_action(action, cog):
				if swap_target(action, cog):
					swapped_actions.append(action)

func check_action(action : ToonAttack, cog : Cog) -> bool:
	if action.targets.size() == 1:
		return cog in action.targets
	return action.main_target == cog

func swap_target(action : ToonAttack, cog : Cog) -> bool:
	var battle := BattleService.ongoing_battle
	var cogs := battle.cogs.duplicate()
	cogs.erase(cog)
	if cogs.is_empty():
		return false
	var new_target : Cog = RandomService.array_pick_random('true_random', cogs)
	
	# Splash retargeting
	if action.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		action.targets.clear()
		action.reassess_splash_targets(battle.cogs.find(new_target), battle)
	else:
		action.targets = [new_target]
	return true

func on_action_started(action : BattleAction) -> void:
	if action is ToonAttack and action in swapped_actions:
		Util.get_player().boost_queue.queue_text("Party Trick!", Color.MEDIUM_PURPLE)
		swapped_actions.erase(action)
