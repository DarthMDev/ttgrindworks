extends CogAttack
class_name RushJob


const gag_job_effect := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_job.tres')


func action() -> void:
	# Get player
	#manager.show_action_name("Rebrand!", "Gives a Max HP buff and Lure Immunity!")
	var cogs = manager.cogs.duplicate()
	var new_target: Cog = RandomService.array_pick_random('true_random', cogs)
	targets = [new_target]
	var cog: Cog = targets[0]
	
	# Focus Cog
	user.set_animation('effort')
	battle_node.focus_character(user)
	
	# Roll for accuracy
	var hit := true
	await manager.sleep(1.2)
	
	# Focus the player
	battle_node.focus_character(cog)
	
	# Apply the status effect
	if hit:
		manager.add_status_effect(create_debuff(cog))
		
		# Player reaction
		#cog.set_animation('finger-wag')
		await manager.sleep(3.0)



func create_debuff(cog : Cog) -> StatBoost:
	var effect := gag_job_effect.duplicate()
	effect.target = cog
	effect.rounds = 0
	return effect
