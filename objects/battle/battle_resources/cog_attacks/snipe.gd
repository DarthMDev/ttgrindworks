extends CogAttack
class_name Snipe

func action():
	# Begin
	user.set_animation('glower')
	manager.s_focus_char.emit(user)
	var target = targets[0]
	user.face_position(target.global_position)
	
	# Start particles after pause
	await manager.sleep(0.9)
	manager.s_focus_char.emit(target)
	var explosion: AnimatedSprite3D = load('res://models/cogs/misc/explosion/cog_explosion.tscn').instantiate()
	manager.battle_node.add_child(explosion)
	var backpack_pos = target.toon.backpack_bone.global_position
	var forward_vector = target.toon.backpack_bone.global_transform.basis.z.normalized()
	explosion.global_position = backpack_pos + forward_vector * 0.2
	#explosion.global_position = target.global_position
	print(target.toon.backpack_bone.global_position)
	
	explosion.scale = Vector3(5, 5, 5)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/ENC_cogfall_apart.ogg'))
	explosion.play('explode')
	target.set_animation('slip_backward')
	await Util.barrier(explosion.animation_finished, 0.5)
	explosion.hide()
	# Roll for accuracy
	var hit := manager.roll_for_accuracy(self)
	if hit:
		manager.affect_target(target, damage)
		#target.set_animation('slip_backward')
	else:
		manager.battle_text(target,"MISSED")
		target.set_animation('sidestep_left')
	
	# Stop particles after pause
	await manager.sleep(0.5)

	
	# Cleanup
	await manager.barrier(target.animator.animation_finished, 4.0)
	
	await manager.check_pulses(targets)
	
