extends CogAttack

func action() -> void:
	var cog: Cog = user
	var player: Player = targets[0]
	
	# MOVIE START
	var movie := manager.create_tween()
	
	# Focus Cog
	movie.tween_callback(cog.face_position.bind(player.global_position))
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('speak'))
	movie.tween_interval(2.0)
	
	# Focus player
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.tween_callback(player.set_animation.bind('slip_backward'))
	movie.tween_callback(manager.affect_target.bind(player, damage))
	movie.tween_interval(4.0)
	
	await movie.finished
	await manager.check_pulses(targets)
	movie.kill()
