extends CogAttack
class_name PoundKey

const PHONE := preload("res://models/props/cog_props/phone_receiver/prop_phone.glb")
const RECEIVER := preload("res://models/props/cog_props/phone_receiver/prop_receiver.glb")
const SFX := preload('res://audio/sfx/battle/cogs/attacks/SA_hangup.ogg')
const PARTICLES := preload('res://objects/battle/effects/pound_key/pound_key.tscn')


func action():
	var hit_anim := 'cringe'
	var miss_anim := 'sidestep_left'
	
	var target = targets[0]
	user.face_position(target.global_position)
	
	user.set_animation('phone')
	
	var phone = PHONE.instantiate()
	var receiver = RECEIVER.instantiate()
	manager.s_focus_char.emit(user)
	user.body.left_hand_bone.add_child(phone)
	phone.add_child(receiver)
	phone.rotation_degrees.x = -90.0
	await manager.sleep(get_pickup_time(user))
	receiver.reparent(user.body.right_hand_bone)
	AudioManager.play_sound(SFX)
	
	# Start particles
	var particles: GPUParticles3D 
	particles = PARTICLES.instantiate()
	phone.add_child(particles)
	particles.position.y = 3.0
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.process_material.gravity = particle_dir * 9.8
	particles.lifetime = sqrt(2.0 * particles.global_position.distance_to(target.head_node.global_position) / 9.8)
	
	# Damage Player
	await manager.sleep(0.75)
	var hit := manager.roll_for_accuracy(self)
	
	if hit:
		manager.s_focus_char.emit(target)
		target.set_animation(hit_anim)
		manager.affect_target(target, damage)
	else:
		manager.s_focus_char.emit(target)
		manager.battle_text(target, "MISSED")
		target.set_animation(miss_anim)
	
	await manager.sleep(get_hangup_time(user))
	if particles:
		particles.emitting = false
	manager.s_focus_char.emit(user)
	
	await manager.sleep(.25)
	receiver.reparent(phone)
	await manager.barrier(user.animator.animation_finished, 4.0)
	phone.queue_free()
	if particles:
		particles.queue_free()
	
	await manager.check_pulses(targets)

func get_pickup_time(cog: Cog) -> float:
	if cog.dna.suit == CogDNA.SuitType.SUIT_A:
		return 1.2
	else:
		return 1.5

func get_hangup_time(cog: Cog) -> float:
	if cog.dna.suit == CogDNA.SuitType.SUIT_A:
		return 1.3
	else:
		return 2.0
