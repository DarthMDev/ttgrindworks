@tool
extends StatEffectRegeneration

const COG_PARTICLES := preload("res://objects/battle/effects/poison/poison_cog.tscn")

var particles: Node3D

## Poison effects only trigger at round ends
func apply() -> void:
	place_particles(target, COG_PARTICLES)
	if target is Player:
		manager.s_battle_ending.connect(cleanup)

func place_particles(who: Node3D, particle_scene: PackedScene) -> void:
	var particle_root: Node
	var particle_scale := 1.0
	if who is Cog:
		particle_root = who.body_root
		particle_scale = 4.0
	elif who is Player:
		particle_root = who.toon
	particles = particle_scene.instantiate()
	particle_root.add_child(particles)
	particles.scale = Vector3.ONE * particle_scale
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

func cleanup() -> void:
	expire()
	if manager.s_battle_ending.is_connected(cleanup):
		manager.s_battle_ending.disconnect(cleanup)

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
	if target:
		amount = ceili(randf_range(ceili(target.stats.max_hp * 0.05), ceili(target.stats.max_hp * 0.1)))
	rounds = -1
