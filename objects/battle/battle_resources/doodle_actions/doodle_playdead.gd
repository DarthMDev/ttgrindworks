extends DoodleAction

const SFX := preload('res://audio/sfx/doodle/play_dead.ogg')


func action():
	# Setup
	var target = targets[0] # Player
	
	# Begin (await an additional half second for pacing)
	await begin_trick()
	await manager.sleep(0.5)
	
	# Show the move's effect
	manager.show_action_name("Luck Boost!")
	
	# Do play dead anim
	user.set_animation('playdead')
	AudioManager.play_sound(SFX)
	await user.animator.animation_finished
	
	# Play the playdead out anim
	user.set_animation('playdead_out')
	await user.animator.animation_finished
	
	# Apply the 1 round status effect
	var stat_effect := create_stat_boost('luck', 0.33)
	manager.add_status_effect(stat_effect)
	
	# Focus player
	manager.s_focus_char.emit(target)
	target.toon.speak("Ha Ha Ha!")
	
	# End
	await end_trick()
