extends CogAttack

const BUBBLE := preload('res://objects/battle/effects/bubble/attack_bubble.tscn')
const GAME := preload('res://objects/battle/misc_battle_objects/tug_of_war/tug_of_war_battle_game.tscn')

func action() -> void:
	var cog : Cog = user
	var player : Player = targets[0]
	var bubble := BUBBLE.instantiate()
	var game := GAME.instantiate()
	
	# Hide player's shadow for this 
	player.toon.get_node('DropShadow').hide()
	
	# MOVIE START
	
	# Focus Cog
	var movie := manager.create_tween()
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('magic1'))
	movie.tween_interval(1.0)
	
	# Place the bubble in its initial position
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.tween_callback(battle_node.add_child.bind(bubble))
	movie.tween_callback(bubble.set_global_position.bind(player.global_position))
	movie.tween_callback(func(): bubble.global_position.y = player.toon.body_node.global_position.y)
	
	# Make bubble grow in
	movie.tween_callback(bubble.set_scale.bind(Vector3(0.01,0.01,0.01)))
	movie.set_trans(Tween.TRANS_SPRING)
	movie.tween_property(bubble, 'scale', Vector3(2,2,2), 0.5)
	movie.set_trans(Tween.TRANS_LINEAR)
	
	
	# Player reacts
	movie.tween_callback(func():
		player.toon.set_emotion(Toon.Emotion.SURPRISE)
		player.toon.set_animation('jump')
		player.toon.animator.seek(0.1, true)
		player.toon.animator.pause()
	)
	
	# Reparent player to bubble
	movie.tween_callback(player.reparent.bind(bubble))
	
	movie.set_ease(Tween.EASE_OUT)
	movie.set_trans(Tween.TRANS_QUINT)
	movie.tween_property(bubble,'rotation_degrees:x', 405.0, 1.5)
	movie.tween_property(bubble,'rotation_degrees:x', 45.0, 0.0)
	movie.set_ease(Tween.EASE_IN_OUT)
	movie.set_trans(Tween.TRANS_LINEAR)
	
	# Setup 
	movie.tween_callback(
	# Make bubble rotate
	func():
		var bubble_rot := manager.create_tween()
		bubble_rot.set_trans(Tween.TRANS_QUAD)
		bubble_rot.tween_property(bubble, 'rotation_degrees:x', -45.0, 3.0)
		bubble_rot.tween_property(bubble, 'rotation_degrees:x', 45.0, 3.0)
		bubble_rot.set_loops()
		game.s_win.connect(bubble_rot.kill)
	)
	movie.tween_interval(2.0)
	
	movie.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.NEUTRAL))
	await movie.finished
	
	# Begin the game
	manager.get_tree().get_root().add_child(game)
	
	# Float player upwards
	var float_tween := manager.create_tween()
	float_tween.set_trans(Tween.TRANS_QUAD)
	float_tween.tween_property(bubble,'position:y', 5.0, 10.0)
	
	# Wait for either the game to end, or the tween to finish
	var game_barrier := SignalBarrier.new([float_tween.finished, game.s_win], SignalBarrier.BarrierType.ANY)
	await game_barrier.s_complete
	
	if float_tween.is_running():
		float_tween.kill()
	if is_instance_valid(game):
		game.queue_free()
	
	var fall_tween := manager.create_tween()
	fall_tween.tween_callback(func():
		player.reparent(battle_node)
		bubble.queue_free()
		player.global_position.x = battle_node.player_pos.x
		player.global_position.z = battle_node.player_pos.z
		player.set_animation('slip-forward')
		player.animator.seek(0.5)
		player.global_rotation = Vector3.ZERO
		battle_node.face_battle_center(player)
	)
	fall_tween.tween_property(player,'position:y', 0.0, 0.25)
	fall_tween.tween_interval(3.0)
	
	await fall_tween.finished
	fall_tween.kill()
	
	player.toon.get_node('DropShadow').show()
	player.toon.get_node('DropShadow/Shadow').position = Vector3.ZERO
