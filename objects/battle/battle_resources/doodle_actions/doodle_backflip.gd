extends DoodleAction



func action():
	# Setup
	var target = targets[0] # Player
	
	# Begin (await an additional half second for pacing)
	await begin_trick()
	await manager.sleep(0.5)
	
	# Show the move's effect
	manager.show_action_name("Defense Boost!")
	
	# Do backflip anim
	user.set_animation('backflip')
	AudioManager.play_sound(load("res://audio/sfx/doodle/backflip.ogg"))
	await user.animator.animation_finished
	
	# Apply the 1 round status effect
	var stat_effect := create_stat_boost('defense', 0.25)
	manager.add_status_effect(stat_effect)
	
	# Focus player
	manager.s_focus_char.emit(target)
	target.toon.speak("Ha Ha Ha!")
	
	# End
	await end_trick()
