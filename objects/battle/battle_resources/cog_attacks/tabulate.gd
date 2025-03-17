extends CogAttack
class_name Tabulate

const CALCULATOR := preload('res://models/props/cog_props/calculator/calculator.glb')
const PARTICLES := preload('res://objects/battle/effects/tabulate/tabulate.tscn')
const SFX := preload("res://audio/sfx/battle/cogs/attacks/SA_audit.ogg")

@export var play_sound := false

func action():
	var hit := manager.roll_for_accuracy(self)
	var target = targets[0]
	user.face_position(target.global_position)
	var calculator : Node3D = CALCULATOR.instantiate()
	user.body.left_hand_bone.add_child(calculator)
	calculator.rotation_degrees = Vector3(-60, 45, 130)
	user.set_animation('phone')
	manager.s_focus_char.emit(user)
	
	
	await manager.sleep(2.0)
	# Start particles
	var particles = PARTICLES.instantiate()
	calculator.add_child(particles)
	particles.position.y = 3.0
	particles.global_position = calculator.global_position
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.gravity = particle_dir*9.8
	particles.lifetime = sqrt(2.0*particles.global_position.distance_to(target.head_node.global_position)/9.8)
	
	# Play sound
	await manager.sleep(0.4)
	if play_sound:
		AudioManager.play_sound(SFX)
	
	manager.s_focus_char.emit(target)
	if hit:
		target.set_animation('conked')
		manager.affect_target(target, damage)
	else:
		target.set_animation('sidestep_left')
		manager.battle_text(target,"MISSED")
	
	await manager.sleep(2.0)
	particles.emitting = false
	
	await user.animator.animation_finished
	calculator.queue_free()
	
	
	await manager.check_pulses(targets)
