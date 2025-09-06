extends ActionScript
#class_name 
var damage := 0



func action() -> void:
	# Get player
	var target = targets[0]
	if target is Player:
		target.set_animation('cringe')
	else: user.set_animation('pie-small')
	battle_node.focus_character(user)
	manager.affect_target(user, damage, true)
	await manager.sleep(3.2)
	await manager.check_pulses([user])
