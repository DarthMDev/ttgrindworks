extends ActionScript
class_name ElevatorReinforcements

func action() -> void:
	var cogs_needed := mini(4 - manager.cogs.size(), 2)
	
	if cogs_needed <= 0:
		return
	
	# Fill the elevator
	var elevator: Elevator = user.elevator_out
	var cogs: Array[Cog] = user.fill_elevator(cogs_needed)
	
	# Focus elevator
	battle_node.battle_cam.global_transform = elevator.elevator_cam.global_transform
	elevator.open()
	await manager.sleep(3.0)
	
	var add_pos := 0
	for cog in manager.cogs:
		if not cog.dna.custom_nametag_suffix == "":
			add_pos = manager.cogs.find(cog) + 1
			break
	
	# Add cogs to battle
	cogs.reverse()
	for cog in cogs:
		manager.add_cog(cog, add_pos)
		cog.battle_start()
	battle_node.focus_cogs()
	battle_node.reposition_cogs()
	await manager.sleep(1.0)
	elevator.close()
	await manager.sleep(3.0)
