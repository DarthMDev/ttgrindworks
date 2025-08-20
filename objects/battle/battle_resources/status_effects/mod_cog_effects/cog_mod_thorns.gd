@tool
extends StatusEffect
var thorn_index = 0
var buff_turn_index = 0
signal s_gag_modified(indexes: Array)  # New signal
var effectdict = {}
var battle_ui
var turns_used = 0
var unstable = false

func apply() -> void:
	var cog: Cog = target
	var playerturns = Util.get_player().stats.turns
	#print(playerturns)
	battle_ui = manager.battle_ui
	thorn_index = RandomService.randi_channel('true_random') % playerturns
	effectdict[thorn_index] = { "effect": 2, "desc": "You will be dealt 15% of the unboosted gag damage dealt this turn", "value": 0.15 }
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
						dmg_dealt += cog.trap.damage * 0.15 * Util.get_player().stats.damage
				Util.get_player().quick_heal(-1 * dmg_dealt)
			elif action is GagTrap:
				pass
			else:
				dmg_dealt = action.damage * 0.15 * Util.get_player().stats.damage
				print(dmg_dealt, action.damage)
				print(action.damage)
				print("toon should lose", dmg_dealt)
				Util.get_player().quick_heal(-1 * dmg_dealt)
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
	#print(playerturns)
	battle_ui = manager.battle_ui
	thorn_index = RandomService.randi_channel('true_random') % playerturns
	effectdict[thorn_index] = { "effect": 2, "desc": "You will be dealt 15% of the unboosted gag damage dealt this turn", "value": 0.15 }
	
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		manager.battle_ui.s_item_effect.emit(effectdict)
	
func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)
	BattleService.s_action_started.disconnect(on_action_started)

func get_status_name() -> String:
	return "Retributive"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/cooked.png")
	#uid://vu8qo2uocf23
