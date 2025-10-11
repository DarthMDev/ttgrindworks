extends GagSquirt
class_name FireHose

func action():
	# Start
	manager.s_focus_char.emit(user)
	var target = targets[0]
	
	# Place hose in hand
	var hose = load('res://models/props/gags/firehose/hose.tscn').instantiate()
	user.toon.add_child(hose)
	
	scale_hose(hose)
	
	# Play hose anim
	hose.get_node('AnimationPlayer').play('spray')
	await Task.delay(0.05)
	user.set_animation('firehose')
	user.face_position(target.global_position)
	
	await Task.delay(1.95)
	# Soak the Cog
	soak_opponent(target.head_node, hose.get_node('firehose/Skeleton3D/NozzleAttach'), 1.0)
	#user.toon.anim_pause()
	#hose.get_node('AnimationPlayer').pause()
	#await Task.delay(10000.0)
	
	
	
	# Play sfx
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/squirt/firehose_spray.ogg"))
	
	await Task.delay(0.1)
	manager.s_focus_char.emit(target)
	
	# Accuracy roll
	if manager.roll_for_accuracy(self) or target.lured:
		var was_lured: bool = target.lured
		manager.affect_target(target, damage)
		var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
		if Util.get_player().stats.has_item('Witch Hat'):
			splat.modulate = POISON_COLOR
		else:
			splat.modulate = Globals.SQUIRT_COLOR
		splat.set_text("SPLASH!")
		target.head_node.add_child(splat)
		if not get_immunity(target):
			if target.lured:
				manager.knockback_cog(target)
				do_dizzy_stars(target)
			else:
				target.set_animation('squirt-small')
				do_dizzy_stars(target)
			apply_debuff(target)
			s_hit.emit()
			await Task.delay(0.5 * (2 if was_lured else 1))
			manager.battle_text(target, "Drenched!", BattleText.colors.orange[0], BattleText.colors.orange[1])
		else:
			manager.battle_text(target, "IMMUNE")
		await manager.barrier(target.animator.animation_finished, 5.0)
		await manager.check_pulses(targets)
	else:
		target.set_animation('sidestep-left')
		manager.battle_text(target, "MISSED")
		await manager.barrier(target.animator.animation_finished, 5.0)
	
	# End
	hose.queue_free()
	user.face_position(manager.battle_node.global_position)

func scale_hose(hose: Node3D) -> void:
	var dna: ToonDNA = Util.get_player().toon.toon_dna
	match {'l': dna.leg_type, 'b': dna.body_type}:
		{'l': ToonDNA.BodyType.SMALL, 'b': ToonDNA.BodyType.MEDIUM}:
			hose.scale *= 0.16
		{'l': ToonDNA.BodyType.MEDIUM, 'b': ToonDNA.BodyType.SMALL}:
			hose.scale *= 0.25
			hose.position = Vector3(0.055, 0.0, 0.0)
		{'l': ToonDNA.BodyType.MEDIUM, 'b': ToonDNA.BodyType.LARGE}:
			hose.scale *= 0.24
		{'l': ToonDNA.BodyType.LARGE, 'b': ToonDNA.BodyType.SMALL}:
			hose.scale *= 0.33
			hose.position = Vector3(0.135, 0.0, -0.305)
		{'l': ToonDNA.BodyType.LARGE, 'b': ToonDNA.BodyType.MEDIUM}:
			hose.scale *= 0.28
			hose.position = Vector3(0.07, 0.0, -0.3)
		{'l': ToonDNA.BodyType.LARGE, 'b': ToonDNA.BodyType.LARGE}:
			hose.scale *= 0.315
			hose.position = Vector3(0.105, 0.0, -0.185)
		_:
			hose.scale *= 0.2
