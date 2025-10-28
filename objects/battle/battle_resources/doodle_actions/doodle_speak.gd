extends DoodleAction

const SFX := preload('res://audio/sfx/doodle/speak_v1.ogg')


func action():
	# Setup
	var target : Player = targets[0] # Player
	
	# Begin (await an additional half second for pacing)
	await begin_trick()
	await manager.sleep(0.5)
	
	# Show the move's effect
	manager.show_action_name("Attack Boost!")
	
	# Do speak anim
	user.set_animation('speak')
	AudioManager.play_sound(SFX)
	await user.animator.animation_finished
	
	# Apply the 1 round status effect
	var stat_effect := create_stat_boost('damage', 0.2)
	manager.add_status_effect(stat_effect)
	
	# Focus player
	manager.s_focus_char.emit(target)
	target.toon.speak("Ha Ha Ha!")
	
	# End
	await end_trick()
