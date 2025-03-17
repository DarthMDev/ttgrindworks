extends ActionScript
class_name BurnAll

## Burns all battle participants
var damage := 5

func action():
	# Display text
	manager.show_action_name("You're burning up!")
	
	# Burn player
	Util.get_player().set_animation('cringe')
	manager.s_focus_char.emit(Util.get_player())
	Util.get_player().last_damage_source = "Molten Lava"
	manager.affect_target(Util.get_player(), damage)
	await Util.get_player().animator.animation_finished
	await manager.check_pulses([Util.get_player()])
	
	# Burn Cogs
	targets = manager.cogs
	manager.battle_node.focus_cogs()
	for target in targets:
		manager.affect_target(target, damage)
		target.set_animation('pie-small')
	await targets[0].animator.animation_finished
	await manager.check_pulses(targets)
