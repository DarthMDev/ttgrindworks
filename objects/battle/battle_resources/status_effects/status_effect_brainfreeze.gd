@tool
extends StatusEffect

@export var turn_skip_chance := 0.2

func apply() -> void:
	manager.s_round_started.connect(on_round_start)
	on_round_start(manager.round_actions)

func on_round_start(actions: Array[BattleAction]) -> void:
	if randf() >= turn_skip_chance:
		return
	for action in actions:
		if action.user == target:
			manager.round_actions.erase(action)

func get_description() -> String:
	if target is Cog:
		return "Brrr! This Cog may be unable to attack!"
	else:
		return "Brrr! Your turn(s) may be skipped!"

func cleanup() -> void:
	manager.s_round_started.disconnect(on_round_start)

func combine(effect: StatusEffect) -> bool:
	if effect.rounds > rounds:
		rounds = effect.rounds
	if effect.turn_skip_chance > turn_skip_chance:
		turn_skip_chance = effect.turn_skip_chance
	return true
