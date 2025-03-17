extends CogAttack
class_name EvilEye


func action():
	# Setup
	var hit := manager.roll_for_accuracy(self)
	var target = targets[0]
	user.face_position(target.global_position)
	var eye: Node3D = load('res://models/props/cog_props/evil_eye/evil_eye.glb').instantiate()
	user.body.head_bone.add_child(eye)
	eye.position += Vector3(-0.5, 1.5, 1.838)
	eye.hide()
	user.set_animation('glower')
	manager.s_focus_char.emit(user)
	
	await manager.sleep(1.6)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_evil_eye.ogg'))
	user.animator.pause()
	eye.show()
	eye.top_level = true
	eye.look_at(target.head_node.global_position)
	eye.scale = Vector3(0.1, 0.1, 0.1)
	var grow_tween : Tween = eye.create_tween()
	var forward_vec := eye.global_transform.basis.z.normalized()
	var distance := -eye.global_position.distance_to(target.head_node.global_position)
	if not hit:
		distance -= 4.0
	var destination := eye.global_position + (forward_vec*distance)
	var speed := 3.25
	grow_tween.tween_property(eye, 'scale', Vector3(3, 3, 3), 1.0)
	grow_tween.tween_interval(0.5)
	grow_tween.tween_callback(user.animator.play)
	grow_tween.tween_property(eye, 'global_position', destination, abs(distance / speed))
	
	# Hit or miss
	if hit:
		await manager.sleep(1.0)
		manager.s_focus_char.emit(target)
		target.set_animation('duck')
		await grow_tween.finished
		eye.queue_free()
		target.set_animation('cringe')
		manager.affect_target(target, damage)
	else:
		manager.s_focus_char.emit(target)
		target.set_animation('duck')
		await manager.sleep(2.0)
		manager.battle_text(target,"MISSED")
	
	await manager.barrier(target.animator.animation_finished, 5.0)
	await manager.check_pulses(targets)
	
	grow_tween.kill()
	
	if is_instance_valid(eye):
		eye.queue_free()
