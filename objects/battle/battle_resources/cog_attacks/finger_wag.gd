extends CogAttack
class_name FingerWag

func action():
	# Begin
	user.set_animation('finger-wag')
	manager.s_focus_char.emit(user)
	var target = targets[0]
	user.face_position(target.global_position)
	
	# Start particles after pause
	await manager.sleep(1.2)
	var particles = load('res://objects/battle/effects/finger_wag/finger_wag.tscn').instantiate()
	user.add_child(particles)
	particles.global_position = user.body.right_index_bone.global_position
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.process_material.gravity = particle_dir*9.8
	particles.lifetime = sqrt(2.0*particles.global_position.distance_to(target.head_node.global_position)/9.8)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_finger_wag.ogg'))
	
	# Additional pause
	await manager.sleep(0.75)
	manager.s_focus_char.emit(target)
	
	# Roll for accuracy
	var hit := manager.roll_for_accuracy(self)
	if hit:
		manager.affect_target(target, damage)
		target.set_animation('slip_backward')
	else:
		manager.battle_text(target,"MISSED")
		target.set_animation('sidestep_left')
	
	# Stop particles after pause
	await manager.sleep(0.5)
	particles.emitting = false
	
	# Cleanup
	await manager.barrier(target.animator.animation_finished, 4.0)
	
	await manager.check_pulses(targets)
	
	particles.queue_free()
