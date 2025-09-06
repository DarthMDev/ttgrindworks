@tool
extends StatusEffect
var thorn_index = 0
var buff_turn_index = 0
signal s_gag_modified(indexes: Array)  # New signal
var effectdict = {}
var battle_ui
var turns_used = 0
var unstable = false
var damage_mult = 0.15
var msg = "You will be dealt 15% of the unboosted gag damage dealt this turn"

func apply() -> void:
	var cog: Cog = target
	var playerturns = Util.get_player().stats.turns
	damage_mult = 0.15 + (playerturns - 3) * 0.1
	msg = "You will be dealt %d%% of the unboosted gag damage dealt this turn" % (damage_mult * 100)
	description = "You will be dealt %d%% of the base damage that occurs on a turn" % (damage_mult * 100)
	battle_ui = manager.battle_ui
	thorn_index = RandomService.randi_channel('true_random') % playerturns
	effectdict[thorn_index] = { "effect": 2, "desc": msg, "value": damage_mult }
	#print("ui sledected gags? line 15")
	await Task.delay(0.1)
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		manager.battle_ui.s_item_effect.emit(effectdict)
	manager.s_gags_chosen.connect(on_gags_chosen)
	BattleService.s_action_started.connect(on_action_started)
	

func on_action_started(action: BattleAction) -> void:
	if target:
		print("thorns stuff and there is a thorny guy")
		if target.stats.hp <= 0:
			return
	else:
		print("thorn stuff no target")
		return
	if action is ToonAttack:
		if turns_used == thorn_index:
			var dmg_dealt = 0
			print("action type: ", action)
			if action is GagLure:
				for cog in action.targets:
					if cog.trap:
						dmg_dealt += cog.trap.damage * damage_mult * Util.get_player().stats.damage
				Util.get_player().quick_heal(-1 * dmg_dealt)
				retributive_attack(dmg_dealt)
			elif action is GagTrap:
				pass
			else:
				dmg_dealt = action.damage * damage_mult * Util.get_player().stats.damage
				print("toon should lose", dmg_dealt)
				retributive_attack(dmg_dealt)
		turns_used += 1

func on_gags_chosen(actions: Array[ToonAttack]) -> void:

	#if(actions.size() -1 >= thorn_index): actions[thorn_index].sheer_force = true
	s_gag_modified.emit([0,1])

func renew() -> void:
	if unstable:
		return
	var playerturns = Util.get_player().stats.turns
	effectdict.clear()
	turns_used = 0
	battle_ui = manager.battle_ui
	thorn_index = RandomService.randi_channel('true_random') % playerturns
	effectdict[thorn_index] = { "effect": 2, "desc": msg, "value": damage_mult }
	if target.stats.hp > target.stats.max_hp * 1.499:
		var thorn_index2 = RandomService.randi_channel('true_random') % playerturns
		if thorn_index == thorn_index2: #ensure thorn_index
			if thorn_index == playerturns - 1:
				thorn_index2 = 0
			else: thorn_index2 = playerturns - 1
		effectdict[thorn_index2] = { "effect": 2, "desc": msg, "value": damage_mult }
	
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		manager.battle_ui.s_item_effect.emit(effectdict)
	if target.stats.hp > target.stats.max_hp * 1.5:
		description = "You will be dealt %d%% of the base damage that occurs on a turn
2 turns if overcharged at start of the round." % (damage_mult * 100) 
	
func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)
	BattleService.s_action_started.disconnect(on_action_started)

func get_status_name() -> String:
	return "Retributive"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/cooked.png")
	#uid://vu8qo2uocf23
func retributive_attack(damage) -> void:
	if damage < 0:
		return
	var attack = load('res://objects/battle/battle_resources/doodle_actions/toon_recoil.tres').duplicate()
	attack.damage = damage
	attack.targets = [Util.get_player()]
	attack.user = Util.get_player()
	manager.inject_battle_action(attack,0)
