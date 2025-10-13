@tool
extends StatusEffect

var turns_added := 0

func apply() -> void:
	manager.s_round_started.connect(on_round_start)
	manager.s_round_ended.connect(on_round_end)
	manager.battle_stats[target].damage *= 0.7

func on_round_start(actions: Array[BattleAction]) -> void:
	var insert_index := 0
	while insert_index < actions.size() and not actions[insert_index].user == target:
		if target in actions[insert_index].targets:
			turns_added += 1
		insert_index += 1
	if insert_index < actions.size():
		if actions[insert_index].user == target:
			for move in turns_added:
				manager.inject_battle_action(manager.get_cog_attack(target), insert_index)
	target.stats.turns += turns_added

func on_round_end() -> void:
	target.stats.turns -= turns_added
	turns_added = 0

func cleanup() -> void:
	manager.s_round_started.disconnect(on_round_start)
	manager.s_round_ended.disconnect(on_round_end)
