@tool
extends StatusEffect
class_name StatusEffectBKMentalMath

const REPRIMAND := preload("res://objects/battle/battle_resources/misc_movies/bookkeeper/bk_reprimand.tres")

@export var wants_targeted := false

var was_targeted := false

func apply():
	manager.s_round_started.connect(round_started)

func round_started(actions: Array[BattleAction]) -> void:
	for action: BattleAction in actions:
		if action is ToonAttack and not action.special_action_exclude:
			if target in action.targets:
				was_targeted = true
				break

func expire() -> void:
	handle_expiry_target_logic()

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func handle_expiry_target_logic() -> void:
	if ((not wants_targeted) and was_targeted) or (wants_targeted and not was_targeted):
		# Add reprimand attack if we don't meet the conditions
		create_reprimand_attack()

func create_reprimand_attack() -> void:
	var reprimand := REPRIMAND.duplicate(true)
	reprimand.user = target
	reprimand.targets = [Util.get_player()]
	manager.round_end_actions.append(reprimand)
