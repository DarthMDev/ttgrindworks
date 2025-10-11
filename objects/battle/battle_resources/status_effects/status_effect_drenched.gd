@tool
extends StatBoost

const PARTICLE := preload("res://objects/battle/effects/drenched/drenched.tscn")

var particles : GPUParticles3D

func apply() -> void:
	super()
	
	particles = PARTICLE.instantiate()
	target.add_child(particles)
	particles.global_position = target.body.head_bone.global_position
	particles.reparent(target.body.head_bone)

func cleanup() -> void:
	super()
	if particles:
		particles.queue_free()

func combine(effect : StatusEffect) -> bool:
	if rounds <= effect.rounds:
		rounds = effect.rounds
		return true
	return true

func get_status_name() -> String:
	return "Drenched"

func randomize_effect() -> void:
	rounds = randi_range(1, 3)
	boost = randf_range(-0.1, -0.5)
