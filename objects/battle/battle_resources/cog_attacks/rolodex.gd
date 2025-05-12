extends CogAttack
class_name Rolodex

func action():
	# Setup
	var hit := manager.roll_for_accuracy(self)
	var target = targets[0]
	user.face_position(target.global_position)
	manager.s_focus_char.emit(user)
	
	# Create the rollodex and position it in the Cog's left hand
	var prop = load('res://models/props/cog_props/rolodex/rolodex.glb').instantiate()
	user.body.left_hand_bone.add_child(prop)
	prop.rotation_degrees = Vector3(80, -90.0, 90.0)
	
	# SuitA has a special position
	if user.dna.suit == CogDNA.SuitType.SUIT_A:
		prop.position = Vector3(-0.8, -0.1 ,0)
	
	# Play the rolodex animation
	user.set_animation('roll-o-dex')
	
	# Await particles
	await manager.sleep(2.6)
	var particles: GPUParticles3D = load('res://objects/battle/effects/rolodex/rolodex_effect.tscn').instantiate()
	user.add_child(particles)
	particles.global_position = user.body.right_index_bone.global_position
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.process_material.gravity = particle_dir * 9.8
	particles.lifetime = sqrt(2.0 * particles.global_position.distance_to(target.head_node.global_position) / 9.8)
	AudioManager.play_sound(load("res://audio/sfx/battle/cogs/attacks/SA_rolodex.ogg"))
	
	# Hit or miss
	if hit:
		await manager.sleep(0.4)
		manager.s_focus_char.emit(target)
		target.set_animation('conked')
		manager.affect_target(target, damage)
		await manager.sleep(1.0)
	else:
		manager.s_focus_char.emit(target)
		target.set_animation('sidestep_left')
		manager.battle_text(target,"MISSED")
		await manager.sleep(1.4)
	particles.emitting = false
	
	# Cleanup
	await manager.barrier(target.animator.animation_finished)
	particles.queue_free()
	prop.queue_free()
	
	await manager.check_pulses(targets)
