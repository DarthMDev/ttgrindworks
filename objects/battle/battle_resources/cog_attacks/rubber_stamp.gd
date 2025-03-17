extends CogAttack
class_name RubberStamp

func action():
	# Setup
	var hit := manager.roll_for_accuracy(self)
	var target: Node3D = targets[0]
	user.face_position(target.global_position)
	manager.s_focus_char.emit(user)
	var stamp: Node3D = load('res://models/props/cog_props/rubber_stamp/rubber_stamp.glb').instantiate()
	var pad: Node3D = load('res://models/props/cog_props/rubber_stamp/stamp_pad.tscn').instantiate()
	user.body.left_hand_bone.add_child(pad)
	match user.dna.suit:
		CogDNA.SuitType.SUIT_C:
			pad.position = Vector3(-0.705, 0.407, -0.111)
			pad.rotation_degrees = Vector3(65.4, -79.3, -73.2)
			pad.scale = Vector3.ONE * 70.0
		CogDNA.SuitType.SUIT_A:
			pad.position = Vector3(-0.93, 0.803, -0.267)
			pad.rotation_degrees = Vector3(-8.6, -94.5, -82)
	user.body.right_hand_bone.add_child(stamp)
	stamp.position = Vector3(-0.669, 0.295, -0.692)
	stamp.rotation_degrees = Vector3(-85, -34, 125)
	user.set_animation('rubber-stamp')
	
	# Do SFX
	await manager.sleep(1.6)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_rubber_stamp.ogg'))
	
	# Make the stamp text
	await manager.sleep(1.5)
	var text: Label3D = load("res://models/props/cog_props/rubber_stamp/stamp_text.tscn").instantiate()
	user.add_child(text)
	text.global_position = user.body.right_hand_bone.global_position
	text.look_at(target.head_node.global_position)
	
	if not hit:
		target.set_animation('sidestep_left')
		manager.battle_text(target, "MISSED")
	
	# Make text approach player
	var stamp_tween: Tween = text.create_tween()
	stamp_tween.tween_property(text, 'global_position', target.head_node.global_position, 0.75)
	await manager.sleep(0.35)
	manager.s_focus_char.emit(target)
	await stamp_tween.finished
	stamp_tween.kill()
	text.queue_free()
	
	if hit:
		target.set_animation('cringe')
		manager.affect_target(target, damage)
	
	await target.animator.animation_finished
	# Cleanup
	stamp.queue_free()
	pad.queue_free()
	target.set_animation('neutral')
	
	await manager.check_pulses(targets)
