extends CogAttack

const PHONE := preload("res://models/props/cog_props/phone_receiver/prop_phone.glb")
const RECEIVER := preload("res://models/props/cog_props/phone_receiver/prop_receiver.glb")
const SFX := preload('res://audio/sfx/battle/cogs/attacks/SA_hangup.ogg')
const ANIM_HIT := 'slip_backward'
const ANIM_MISS := 'happy'

func action() -> void:
	# Roll for accuracy
	var hit := manager.roll_for_accuracy(self)
	
	# Create the phone and receiver
	var phone := PHONE.instantiate()
	var receiver := RECEIVER.instantiate()
	var player: Player = targets[0]
	user.body.left_hand_bone.add_child(phone)
	phone.add_child(receiver)
	phone.rotation_degrees.x = -90.0
	
	# Movie Start
	var movie := manager.create_tween()
	
	# Show Cog dialing
	movie.tween_callback(battle_node.focus_character.bind(user))
	movie.tween_callback(user.set_animation.bind('phone'))
	movie.tween_interval(get_pickup_time(user))
	movie.tween_callback(AudioManager.play_sound.bind(SFX))
	
	# Receiver pickup/putdown timing
	movie.tween_callback(receiver.reparent.bind(user.body.right_hand_bone))
	movie.tween_interval(get_hangup_time(user))
	movie.tween_callback(receiver.reparent.bind(phone))
	movie.tween_interval(3.0)
	
	# Player reacts
	movie.tween_callback(battle_node.focus_character.bind(player))
	if hit:
		movie.tween_callback(player.set_animation.bind(ANIM_HIT))
		movie.tween_callback(manager.affect_target.bind(player, damage))
		movie.tween_interval(3.5)
	else:
		movie.tween_callback(player.set_animation.bind(ANIM_MISS))
		movie.tween_callback(manager.battle_text.bind(player,"MISSED"))
		movie.tween_interval(3.0)
	
	await movie.finished
	await manager.check_pulses(targets)
	phone.queue_free()
	movie.kill()

func get_pickup_time(cog: Cog) -> float:
	if cog.dna.suit == CogDNA.SuitType.SUIT_A:
		return 1.2
	else:
		return 1.5

func get_hangup_time(cog: Cog) -> float:
	if cog.dna.suit == CogDNA.SuitType.SUIT_A:
		return 2.3
	else:
		return 3.0
