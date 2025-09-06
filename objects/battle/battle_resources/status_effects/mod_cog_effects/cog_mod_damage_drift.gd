@tool
extends StatusEffect
var debuff_turn_index = 0
var buff_turn_index = 0
var buff_amount = 1.15
var nerf_amount = 0.5
signal s_gag_modified(indexes: Dictionary)  # New signal
var effectdict = {}
var battle_ui 

func apply() -> void:
	if Util.final_boss:
		buff_amount = 1.1
		nerf_amount = 0.6
	var cog: Cog = target
	var playerturns = Util.get_player().stats.turns
	battle_ui = manager.battle_ui
	debuff_turn_index = RandomService.randi_channel('true_random') % playerturns
	buff_turn_index = RandomService.randi_channel('true_random') % playerturns
	if debuff_turn_index not in effectdict : effectdict[debuff_turn_index] = nerf_amount
	else: effectdict[debuff_turn_index] = effectdict[debuff_turn_index] * nerf_amount
	if buff_turn_index not in effectdict: effectdict[buff_turn_index] = buff_amount
	else: effectdict[buff_turn_index] = effectdict[buff_turn_index] * buff_amount
	await Task.delay(0.1)
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		battle_ui.s_damage_drifted.emit(effectdict)
	manager.s_gags_chosen.connect(on_gags_chosen)


func on_gags_chosen(actions: Array[ToonAttack]) -> void:
	#print("line 20 on damage drift")
	if(actions.size() -1 >= debuff_turn_index):
		#print("pre nerf: ", actions[debuff_turn_index].damage,"damage on", actions[debuff_turn_index].action_name)
		actions[debuff_turn_index].damage *= nerf_amount
		#print("After, ", actions[debuff_turn_index].damage)
	if(actions.size() -1 >= buff_turn_index):
		#print("pre buff: ", actions[buff_turn_index].damage,"damage on", actions[buff_turn_index].action_name)
		actions[buff_turn_index].damage *= buff_amount
		#print("After, ", actions[buff_turn_index].damage)
	s_gag_modified.emit([debuff_turn_index, buff_turn_index])

func renew() -> void:
	var playerturns = Util.get_player().stats.turns
	debuff_turn_index = RandomService.randi_channel('true_random') % playerturns 
	buff_turn_index =  RandomService.randi_channel('true_random') % playerturns
	effectdict.clear()
	if debuff_turn_index not in effectdict : effectdict[debuff_turn_index] = nerf_amount
	else: effectdict[debuff_turn_index] = effectdict[debuff_turn_index] * nerf_amount
	if buff_turn_index not in effectdict: effectdict[buff_turn_index] = buff_amount
	else: effectdict[buff_turn_index] = effectdict[buff_turn_index] * buff_amount
	
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		battle_ui.s_damage_drifted.emit(effectdict)
	
func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)

func get_status_name() -> String:
	return "Damage Drift"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/damage_drift.png")
