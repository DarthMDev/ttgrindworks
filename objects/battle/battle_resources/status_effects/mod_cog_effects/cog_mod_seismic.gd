@tool
extends StatusEffect

var aftershock_multiplier = 0.5
const DEBUFF := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres")

func apply() -> void:
	var cog: Cog = target
	manager.s_action_started.connect(on_action_start)

func on_action_start(action : BattleAction) -> void:
	if action.user == target and action.target_type != BattleAction.ActionTarget.SELF:
		var aftershock_amount = manager.get_damage(action.damage, action, Util.get_player()) * aftershock_multiplier
		var new_effect: StatEffectAftershock = DEBUFF.duplicate()
		new_effect.amount = roundi(aftershock_amount)
		new_effect.description = "%d damage per round" % new_effect.amount
		new_effect.target = Util.get_player()
		new_effect.rounds = 1
		manager.add_status_effect(new_effect)
		


func cleanup() -> void:
	manager.s_action_started.disconnect(on_action_start)

func get_status_name() -> String:
	return "Seismic"
