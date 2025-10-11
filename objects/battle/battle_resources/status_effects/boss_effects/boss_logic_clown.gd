@tool
extends StatusEffect

const ACTION_QUIZ := preload('res://objects/battle/battle_resources/cog_attacks/resources/pop_quiz_joke.tres')

var quiz_round := 0

func apply() -> void:
	var cog : Cog = target
	if cog.dna.suit == CogDNA.SuitType.SUIT_B:
		quiz_round = 1
	manager.s_round_started.connect(round_started)

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func round_started(_actions : Array[BattleAction]) -> void:
	if manager.current_round % 2 == quiz_round:
		queue_quiz()

func queue_quiz() -> void:
	var action := ACTION_QUIZ.duplicate(true)
	action.user = target
	action.targets = [Util.get_player()]
	manager.round_end_actions.append(action)
