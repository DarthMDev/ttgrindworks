extends CogAttack
class_name MoleCogLaunch

const SFX_LAUNCH := preload("res://audio/sfx/objects/moles/Mole_Surprise.ogg")
const SFX_GRUNT := preload("res://audio/sfx/toon/target_impact_grunt1.ogg")
const SFX_IMPACT := preload("res://audio/sfx/misc/target_impact_only.ogg")
const SFX_STOMP := preload("res://audio/sfx/misc/ENC_cogjump_to_side.ogg")

const MOLE_HOLE := preload('res://objects/interactables/mole_stomp/mole_hole.tscn')


func action() -> void:
	var player : Player = targets[0]
	
	# Create the mole hill for the attack
	var mole_hill := MOLE_HOLE.instantiate()
	battle_node.add_child(mole_hill)
	mole_hill.hide()
	mole_hill.global_position = player.global_position
	mole_hill.rotation_degrees.y += 180.0
	mole_hill.scale *= 0.1
	
	# Accuracy check
	var hit := manager.roll_for_accuracy(self)
	
	# Movie Start
	var movie := manager.create_tween()
	
	# Focus Cog
	movie.tween_callback(battle_node.focus_character.bind(user, 6.0))
	movie.tween_callback(user.set_animation.bind('stomp'))
	movie.tween_interval(0.6)
	movie.tween_callback(AudioManager.play_sound.bind(SFX_STOMP))
	movie.tween_interval(1.4)
	
	# Mole Pops up
	movie.tween_callback(mole_hill.show)
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_property(mole_hill,'scale', Vector3(1.0,1.0,1.0), 0.5)
	movie.set_trans(Tween.TRANS_LINEAR)
	movie.tween_property(mole_hill.mole_norm, 'position:y', MoleHole.UP_Y, 0.5)
	
	if hit:
		movie.tween_callback(mole_hill.mole_norm.hide)
		movie.tween_callback(mole_hill.mole_surprised.show)
		movie.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.SURPRISE))
	
		# Toon flies away into the stratosphere
		movie.tween_callback(AudioManager.play_sound.bind(SFX_LAUNCH))
		movie.tween_callback(player.set_animation.bind('run'))
		movie.tween_property(player.toon, 'position:y', 20, 1.5)
		movie.tween_property(player.toon, 'position:y', 0.0, 1.5)
		movie.parallel().tween_callback(player.set_animation.bind('slip_forwards')).set_delay(1.0)
		movie.parallel().tween_property(mole_hill.mole_surprised, 'position:y', -1.0, 1.0)
		movie.tween_callback(manager.affect_target.bind(player, damage))
		movie.tween_callback(AudioManager.play_sound.bind(SFX_GRUNT))
		movie.tween_callback(AudioManager.play_sound.bind(SFX_IMPACT))
	else:
		movie.parallel().tween_callback(player.set_animation.bind('sidestep_left'))
		movie.tween_callback(manager.battle_text.bind(player, "MISSED"))
		movie.tween_interval(1.0)
		movie.tween_property(mole_hill.mole_norm,'position:y', -1.0, 1.0)
	
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_property(mole_hill,'scale', Vector3(0.01,0.01,0.01), 0.5)
	movie.tween_interval(3.0)
	movie.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.NEUTRAL))
	
	await movie.finished
	movie.kill()
	
	await manager.check_pulses(targets)
	mole_hill.queue_free()
