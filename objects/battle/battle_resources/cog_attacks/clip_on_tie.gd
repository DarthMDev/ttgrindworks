extends CogAttack

@export var model : PackedScene
@export var model_rotation := Vector3.ZERO
@export var model_scale := Vector3.ONE
@export var model_position := Vector3.ONE
@export var sfx_throw : AudioStream
@export var sfx_impact : AudioStream


func action() -> void:
	var prop : Node3D = model.instantiate()
	var cog : Cog = user
	var player : Player = targets[0]
	var hit := manager.roll_for_accuracy(self)
	
	cog.body.right_hand_bone.add_child(prop)
	prop.scale = model_scale
	prop.position = model_position
	prop.rotation = model_rotation
	
	var tween := manager.create_tween()
	
	# Windup
	tween.tween_callback(cog.set_animation.bind('throw-paper'))
	tween.tween_callback(battle_node.focus_character.bind(cog))
	if cog.dna.suit == CogDNA.SuitType.SUIT_C:
		tween.tween_interval(2.3)
	else:
		tween.tween_interval(3.1)
	
	# Focus player
	tween.tween_callback(battle_node.focus_character.bind(player))
	
	# Dodge 
	if not hit:
		tween.tween_callback(player.set_animation.bind('sidestep_left'))
		tween.tween_callback(manager.battle_text.bind(player, "MISSED"))
	
	# Tween tie over
	tween.tween_callback(prop.reparent.bind(battle_node))
	if sfx_throw:
		tween.tween_callback(AudioManager.play_sound.bind(sfx_throw))
	tween.tween_property(prop, 'global_position', player.head_node.global_position, 0.5)
	
	# Hit player
	if hit:
		if sfx_impact:
			tween.tween_callback(AudioManager.play_sound.bind(sfx_impact))
		tween.tween_callback(player.set_animation.bind('cringe'))
		tween.tween_callback(manager.affect_target.bind(player, damage))
	
	tween.tween_callback(prop.queue_free)
	tween.tween_interval(3.0)
	
	
	await tween.finished
	tween.kill()
	await manager.check_pulses(targets)
