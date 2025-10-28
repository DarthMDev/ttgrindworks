@tool
extends StatusEffect

@export var heal_perc := 0.05

var target_hp := 0

func apply() -> void:
	target_hp = target.stats.hp
	target.stats.hp_changed.connect(hp_change)

func hp_change(hp: int) -> void:
	if not manager.current_action:
		return
	var user = manager.current_action.user
	if not is_instance_valid(user) or not 'stats' in user or not user.stats is BattleStats:
		return
	
	if hp < target_hp:
		manager.affect_target(user, -get_heal(target_hp - hp))
	target_hp = hp

func cleanup() -> void:
	if is_instance_valid(target):
		target.stats.hp_changed.disconnect(hp_change)

func get_heal(dmg: int) -> int:
	return ceili(dmg * heal_perc)

func get_status_name() -> String:
	return "Laff Leech"

func get_description() -> String:
	return "Damage taken heals attacker by %s" %  Util.float_to_perc(heal_perc)

func combine(effect: StatusEffect) -> bool:
	if 'heal_perc' in effect:
		heal_perc += effect.heal_perc
		return true
	return false
