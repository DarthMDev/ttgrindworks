@tool
extends StatEffectRegeneration
class_name StatEffectAftershock

func renew() -> void:
	# Don't do movie for dead actors
	if not is_instance_valid(target) or target.stats.hp <= 0:
		return
	
	manager.battle_node.focus_character(target)
	manager.affect_target(target, amount)
	if target is Player:
		target.set_animation('cringe')
	else:
		target.last_damage_source = "Drop"
		target.set_animation('pie-small')
	await manager.sleep(3.0)
	await manager.check_pulses([target])

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/aftershock_dot.png")

func get_status_name() -> String:
	return "Aftershock"

func get_description() -> String:
	if not description == "":
		return description
	return "%d damage per round" % amount

func combine(effect: StatusEffect) -> bool:
	if effect.rounds == rounds:
		amount += effect.amount
		return true
	return false

func randomize_effect() -> void:
	super()
