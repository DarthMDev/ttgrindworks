@tool
extends StatusEffect

var player: Player
var last_player_hp
const STATUS_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_budget_cuts.tres')
const ACTION_OVERTIME := preload("res://objects/battle/battle_resources/misc_movies/whistleblower/overtime.tres")
const ACTION_COMPENSATION := preload("res://objects/battle/battle_resources/misc_movies/whistleblower/compensation.tres")
var unstable = false
var cogs := {}
func apply() -> void:
	var cog: Cog = target
	player  = Util.get_player()
	player.stats.hp_changed.connect(on_toon_heal)
	manager.s_action_started.connect(on_action_started)
	manager.s_round_started.connect(round_started)
	manager.s_actions_ended.connect(round_ended)
	last_player_hp = player.stats.hp

func on_toon_heal(health : int) -> void:
	if(health < last_player_hp and health != last_player_hp):
		if player.last_damage_source == "Whistleblower Fan":
			await manager.sleep(0.26)
			manager.battle_text(Util.get_player(),"Budget Cuts!")
		var hp_ratio = float(health - last_player_hp) / player.stats.max_hp
		
	last_player_hp = health
	
func on_action_started(action: BattleAction) -> void:
	#holy yap
	if action is CogAttack and action.target_type != BattleAction.ActionTarget.SELF and action.action_name != "Overtime" and action.action_name != "Compensation":
		if action.user == target:
			#action.custom_player_death_source = "Whistleblower Fan"
			player.last_damage_source = "Whistleblower Fan"
			apply_status_effect()
func round_started(_actions: Array[BattleAction]) -> void:
	
	# For compensation
	cogs.clear()
	for cog in manager.cogs:
		cogs[cog] = cog.stats.hp

func round_ended() -> void:
	if not target.stats.hp > target.stats.max_hp * 1.5:
		return
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

func renew() -> void:
	if target.stats.hp < target.stats.max_hp * 0.7:
		queue_overtime()

func cleanup() -> void:
	player.stats.hp_changed.disconnect(on_toon_heal)
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)
	if manager.s_actions_ended.is_connected(round_ended):
		manager.s_actions_ended.disconnect(round_ended)
	if manager.s_action_started.is_connected(on_action_started):
		manager.s_action_started.disconnect(on_action_started)

func get_status_name() -> String:
	return "Whistleblower Fan"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/gags/inventory_whistle.png")
var prev_banned_track := ""
func apply_status_effect() -> void:
	var effect := STATUS_EFFECT.duplicate()
	effect.target = player
	var tracks := Util.get_player().stats.gag_regeneration.keys()
	tracks.erase(prev_banned_track)
	tracks.erase("Throw")
	var track = RandomService.array_pick_random('true_random', tracks)
	prev_banned_track = track
	effect.track_name = track
	effect.rounds = 1
	manager.add_status_effect(effect)

func queue_overtime() -> void:
	# Try to find a non boss cog
	var potential_cogs : Array[Cog] = []
	for cog in manager.cogs:
		if not cog.dna.custom_nametag_suffix == "Director" and cog != target:
			potential_cogs.append(cog)
	if potential_cogs.is_empty():
		return
	
	# Create the action
	var action := ACTION_OVERTIME.duplicate()
	action.user = target
	action.targets = [RandomService.array_pick_random('true_random', potential_cogs)]
	manager.round_end_actions.append(action)
