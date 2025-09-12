extends CogAttack
class_name Recoil




func action() -> void:
	# Get player
	
	# Focus Cog
	user.set_animation('pie-small')
	battle_node.focus_character(user)
	manager.affect_target(user, damage, true)
	await manager.sleep(3.2)
	await manager.check_pulses([user])
	
