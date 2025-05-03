@tool
extends StatusEffect


func apply() -> void:
	manager.s_round_started.connect(on_round_start)

func on_round_start(actions : Array[BattleAction]) -> void:
	var inject_pos := 0
	for i in actions.size():
		if actions[i] is ToonAttack or actions[i] is CogAttack:
			inject_pos = i
			break
	
	for action in actions:
		if action.user == target:
			manager.round_actions.erase(action)
			manager.round_actions.insert(inject_pos, action)
