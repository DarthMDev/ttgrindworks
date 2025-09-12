@tool
extends StatusEffect

const ACTION_COMPENSATION := preload("res://objects/battle/battle_resources/misc_movies/whistleblower/compensation.tres")
const ACTION_BUDGET := preload("res://objects/battle/battle_resources/misc_movies/whistleblower/budget_cuts.tres")
const ACTION_OVERTIME := preload("res://objects/battle/battle_resources/misc_movies/whistleblower/overtime.tres")

func apply() -> void:
	manager.s_round_started.connect(round_started)
	manager.s_actions_ended.connect(round_ended)

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)
	if manager.s_actions_ended.is_connected(round_ended):
		manager.s_actions_ended.disconnect(round_ended)

var cogs := {}

func round_started(_actions: Array[BattleAction]) -> void:
	
	# For compensation
	cogs.clear()
	for cog in manager.cogs:
		cogs[cog] = cog.stats.hp
	
	# For budget cuts
	if manager.current_round % 3 == 1:
		queue_budget_cuts()
	# For overtime
	if manager.current_round % 3 == 2:
		queue_overtime()

func round_ended() -> void:
	var damaged_cogs : Array[Cog] = []
	for cog in manager.cogs:
		if cog in cogs.keys():
			if cogs[cog] > cog.stats.hp and cog.stats.hp > 0:
				damaged_cogs.append(cog)
	report_damaged_cogs(damaged_cogs)

func report_damaged_cogs(cogs_arr : Array[Cog]) -> void:
	cogs_arr.erase(target)
	
	if cogs_arr.is_empty():
		return
	
	var new_action := ACTION_COMPENSATION.duplicate()
	new_action.user = target
	new_action.targets = cogs_arr.duplicate()
	manager.round_end_actions.append(new_action)

var prev_banned_track := ""
func queue_budget_cuts() -> void:
	# Setup
	var new_action := ACTION_BUDGET.duplicate()
	new_action.user = target
	new_action.targets = [Util.get_player()]
	
	# Roll for new track
	var tracks := Util.get_player().stats.gag_regeneration.keys()
	tracks.erase(prev_banned_track)
	tracks.erase("Throw")
	new_action.track = RandomService.array_pick_random('true_random', tracks)
	prev_banned_track = new_action.track
	
	# Append action
	manager.round_end_actions.append(new_action)


func queue_overtime() -> void:
	# Try to find a non boss cog
	var potential_cogs : Array[Cog] = []
	for cog in manager.cogs:
		if not cog.dna.custom_nametag_suffix == "Director":
			potential_cogs.append(cog)
	if potential_cogs.is_empty():
		return
	
	# Create the action
	var action := ACTION_OVERTIME.duplicate()
	action.user = target
	action.targets = [RandomService.array_pick_random('true_random', potential_cogs)]
	manager.round_end_actions.append(action)
