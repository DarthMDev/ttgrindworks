@tool
extends StatEffectRegeneration
class_name StatEffectBKCooked

var particles: GPUParticles3D
var bookkeeper: Cog

## Poison effects only trigger at round ends
func apply():
	if bookkeeper:
		manager.s_participant_died.connect(check_participant_died)

func check_participant_died(participant: Node3D) -> void:
	if bookkeeper and bookkeeper == participant:
		manager.expire_status_effect(self)

func renew() -> void:
	# Don't do movie for dead actors
	if not is_instance_valid(target) or target.stats.hp <= 0:
		return
	
	manager.battle_node.focus_character(target)
	manager.affect_target(target, amount, true)
	if target is Player:
		target.last_damage_source = "Spontaneous Combustion"
		target.set_animation('cringe')
	else:
		target.set_animation('pie-small')
	await manager.sleep(3.0)
	await manager.check_pulses([target])

func cleanup() -> void:
	if manager.s_participant_died.is_connected(check_participant_died):
		manager.s_participant_died.disconnect(check_participant_died)

func get_status_name() -> String:
	return "Cooked"

func get_description() -> String:
	return "%s damage per round" % amount
