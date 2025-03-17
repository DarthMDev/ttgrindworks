extends CogAttack
class_name WriteOff

func action():
	var hit := manager.roll_for_accuracy(self)
	var target : Node3D = targets[0]
	user.face_position(target.global_position)
	manager.s_focus_char.emit(user)
	var pad : Node3D = load('res://models/props/cog_props/pencil/pad.glb').instantiate()
	var pencil : Node3D = load('res://models/props/cog_props/pencil/pencil.glb').instantiate()
	user.body.left_hand_bone.add_child(pad)
	pad.position = Vector3(-0.27, -0.314, -0.083)
	pad.rotation_degrees.x = 90
	user.body.right_hand_bone.add_child(pencil)
	pencil.position = Vector3(-0.15, 0.67, 0.0)
	pencil.rotation_degrees.x = 285
	user.set_animation('hold-pencil')
	
	
	await manager.sleep(2.2)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_writeoff_pen_only.ogg'))
	
	await manager.sleep(1.0)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_writeoff_ding_only.ogg'))
	
	var check = Sprite3D.new()
	user.add_child(check)
	check.texture = load("res://models/props/cog_props/pencil/checkmark.png")
	check.global_position = user.body.right_hand_bone.global_position
	check.look_at(target.head_node.global_position)
	check.scale*=2.0
	
	if not hit:
		target.set_animation('sidestep_left')
		manager.battle_text(target,"MISSED")
	
	var check_tween : Tween = check.create_tween()
	check_tween.tween_property(check,'global_position',target.head_node.global_position,0.5)
	await manager.sleep(0.25)
	manager.s_focus_char.emit(target)
	await check_tween.finished
	check.queue_free()
	
	if hit:
		target.set_animation('slip_forwards')
		manager.affect_target(target, damage)
	
	await manager.barrier(target.animator.animation_finished, 4.0)
	pencil.queue_free()
	pad.queue_free()
	
	await manager.check_pulses(targets)
