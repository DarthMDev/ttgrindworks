extends CogAttack

func action():
	var tracks : Array[String] = []
	var loadout := Util.get_player().stats.character.gag_loadout.loadout
	for gagtrack in loadout:
		tracks.append(gagtrack.track_name)
	var steal_track: String = tracks.pick_random()
	manager.show_action_name(action_name + "!","%s steals your %s points!" % [user.dna.cog_name, steal_track])
	
	# Setup
	var hit := manager.roll_for_accuracy(self)
	var target : Player = targets[0]
	user.face_position(target.global_position)
	
	# Play sound
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_pick_pocket.ogg'))
	user.set_animation('pickpocket')
	manager.s_focus_char.emit(user)
	
	# Base toon anim on whether target was hit
	if hit:
		target.set_animation('cringe')
	else:
		target.set_animation('sidestep-left')
		
	
	# Swap camera angle after 0.5 seconds
	await manager.sleep(0.5)
	manager.s_focus_char.emit(target)
	
	# Affect target, or don't
	if hit:
		target.stats.gag_balance[steal_track] = -1
	else:
		manager.battle_text(target,"MISSED")
	
	await user.animator.animation_finished
	
	await manager.check_pulses(targets)
