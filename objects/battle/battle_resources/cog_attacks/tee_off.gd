extends CogAttack
class_name TeeOff

func action():
	# Begin
	user.set_animation('golf-club-swing')
	var target = targets[0]
	user.face_position(target.global_position)
	manager.s_focus_char.emit(user)
	
	# Make golf club
	var club = load('res://models/props/cog_props/golf/golf_club.glb').instantiate()
	user.body.left_hand_bone.add_child(club)
	club.rotation_degrees = Vector3(-20, 0, -120)
	
	# Make golf ball
	var ball = load('res://models/props/cog_props/golf/golf_ball.glb').instantiate()
	user.body.add_child(ball)
	ball.position = Vector3(3.651,0.0,-0.75)
	
	# Roll for accuracy 
	var hit := manager.roll_for_accuracy(self)
	
	# Start miss animation if not hit
	# Wait until club hits ball
	if not hit:
		await manager.sleep(2.0)
		manager.battle_node.focus_cogs()
		target.set_animation('duck')
		await manager.sleep(2.26)
	else:
		await manager.sleep(4.26)
	
	# Make ball fly at target
	ball.top_level = true
	var shoot_tween : Tween = ball.create_tween()
	shoot_tween.tween_property(ball,'global_position',target.head_node.global_position,0.5)
	manager.s_focus_char.emit(target)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_tee_off.ogg'))
	
	# Wait for ball to hit target
	await shoot_tween.finished
	ball.queue_free()
	
	# Hit or not hit
	if hit:
		target.set_animation('conked')
		manager.affect_target(target, damage)
	else:
		manager.battle_text(target, "MISSED")
	
	# End
	if target.stats.hp > 0:
		await manager.barrier(target.animator.animation_finished, 4.0)
	club.queue_free()
	
	await manager.check_pulses(targets)
