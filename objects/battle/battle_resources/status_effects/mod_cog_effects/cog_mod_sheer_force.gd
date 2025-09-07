@tool
extends StatusEffect
var skip_index = 0
var buff_turn_index = 0
signal s_gag_modified(indexes: Array)  # New signal
var effectdict = {}
var battle_ui
var unstable = false

func apply() -> void:
	var cog: Cog = target
	var playerturns = Util.get_player().stats.turns
	battle_ui = manager.battle_ui
	if playerturns >= 2:
		skip_index = RandomService.randi_channel('true_random') % playerturns
		if skip_index == 0:
			skip_index+= 1
		if unstable:
			var skip_index2 = skip_index
			while skip_index != skip_index2:
				skip_index2 = RandomService.randi_channel('true_random') % playerturns
			for i in range(playerturns):
				if i != skip_index and i != skip_index2:
					effectdict[i] = {
						"effect": 1,
						"desc": "Gag secondary effects disabled",
						"value": true
					}
		else:
			for i in range(playerturns):
				if i != skip_index:
					effectdict[i] = {
						"effect": 1,
						"desc": "Gag secondary effects disabled",
						"value": true
					}
	else: effectdict[0] = { "effect": 1, "desc": "Gag secondary effects disabled", "value": true }
	#print("ui sledected gags? line 15")
	await Task.delay(0.1)
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		manager.battle_ui.s_item_effect.emit(effectdict)
	manager.s_gags_chosen.connect(on_gags_chosen)


func on_gags_chosen(actions: Array[ToonAttack]) -> void:
	for i in range(Util.get_player().stats.turns):
		if i != skip_index:
			if(actions.size() -1 >= i): actions[i].sheer_force = true
	s_gag_modified.emit([0,1])

func renew() -> void:
	if unstable:
		return
	var playerturns = Util.get_player().stats.turns
	effectdict.clear()
	battle_ui = manager.battle_ui
	if playerturns >= 2:
		skip_index = RandomService.randi_channel('true_random') % playerturns 
		for i in range(playerturns):
			if i != skip_index:
				effectdict[i] = {
					"effect": 1,
					"desc": "Gag secondary effects disabled",
					"value": true
				}
	else: effectdict[0] = { "effect": 1, "desc": "Gag secondary effects disabled", "value": true }
	
	if battle_ui:
		battle_ui.drift_effect_dict = effectdict
		manager.battle_ui.s_item_effect.emit(effectdict)
	
func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)

func get_status_name() -> String:
	return "Suppressive"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/sheer_force.png")
