@tool
extends StatEffectRegeneration
class_name StatEffectPoison

const COG_PARTICLES := preload("res://objects/battle/effects/poison/poison_cog.tscn")

var particles: Node3D

## Poison effects only trigger at round ends
func apply() -> void:
	if target is Cog:
		place_particles(target, COG_PARTICLES)

func place_particles(who: Node3D, particle_scene: PackedScene) -> void:
	particles = particle_scene.instantiate()
	if who.get_node_or_null(NodePath(particles.name)):
		var old_particles: Node = who.get_node(NodePath(particles.name))
		old_particles.set_name("removing")
		old_particles.queue_free()
	who.body_root.add_child(particles)
	particles.scale *= 4.0
	particles.position.y = 0.05

func renew() -> void:
	# Don't do movie for dead actors
	if not is_instance_valid(target) or target.stats.hp <= 0:
		return
	
	manager.battle_node.focus_character(target)
	manager.affect_target(target, amount)
	if target is Player:
		target.set_animation('cringe')
	else:
		target.set_animation('pie-small')
	if is_instance_valid(particles):
		particles.get_node('AnimationPlayer').play('on_apply')
	await manager.sleep(3.0)
	await manager.check_pulses([target])

func expire() -> void:
	if is_instance_valid(particles):
		particles.queue_free()

func get_status_name() -> String:
	return "Poison"

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
	rounds = -1
