extends CogAttack

const BLANKET_EFFECT := preload("res://objects/battle/effects/power_trip/power_trip_effect.tscn")
const TRIP_EFFECT := preload("res://objects/battle/effects/power_trip/power_trip_bar.tscn")


func action() -> void:
	# Variable setup
	var player : Player = targets[0]
	var cog : Cog = user
	var hit := manager.roll_for_accuracy(self)
	var blanket := BLANKET_EFFECT.instantiate()
	var trip := TRIP_EFFECT.instantiate()
	trip.emitting = false
	cog.add_child(trip)
	
	# Movie Start
	var movie := manager.create_tween()
	
	# Focus Cog
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('magic1'))
	movie.tween_interval(0.5)
	
	# Add effect blanket
	movie.tween_callback(cog.add_child.bind(blanket))
	movie.tween_callback(blanket.set_position.bind(Vector3(0.0, 0.8, 1.42)))
	movie.tween_callback(blanket.set_rotation_degrees.bind(Vector3(30.0, 0.0, 0.0)))
	movie.tween_interval(0.5)
	
	
	# Move to player focus and switch effects
	movie.tween_callback(set_camera_angle.bind('SIDE_RIGHT'))
	movie.tween_callback(trip.set_emitting.bind(true))
	movie.tween_callback(trip.set_position.bind(Vector3(0.0, 0.0, 2.33)))
	
	# Move trip effect
	var destination := player.toon.to_global(player.toon.position - Vector3(0.0, 0.0, 1.0))
	movie.tween_property(trip, 'global_position', destination, 0.75)
	
	# Set player anim to jump if dodged
	if not hit:
		movie.parallel().tween_callback(player.set_animation.bind('happy'))
		movie.parallel().tween_callback(manager.battle_text.bind(player, "MISSED"))
	else:
		movie.parallel().tween_callback(manager.affect_target.bind(player, damage)).set_delay(0.5)
		movie.parallel().tween_callback(player.set_animation.bind('slip_forwards')).set_delay(0.5)
	
	
	movie.tween_callback(trip.queue_free)
	movie.tween_callback(blanket.queue_free)
	
	movie.tween_interval(3.0)
	
	await movie.finished
	movie.kill()
	
	await manager.check_pulses(targets)
