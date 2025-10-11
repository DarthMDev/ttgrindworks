extends CogAttack

const COG_OBJECT := preload('res://objects/cog/cog.tscn')

@export_range(1, 3) var cog_amount := 3

var spawn_proxies := false


func action() -> void:
	var user_cog : Cog = user
	
	battle_node.focus_character(user_cog)
	await manager.sleep(3.0)
	
	var new_cogs : Array[Cog] = []
	
	# Create our new Cog objects
	for i in cog_amount:
		var new_cog := COG_OBJECT.instantiate()
		if spawn_proxies:
			new_cog.use_mod_cogs_pool = true
			new_cog.level_range_offset = -1
		new_cogs.append(new_cog)
		new_cog.hide()
		battle_node.add_child(new_cog)
		new_cog.battle_start()
		BattleService.ongoing_battle.add_cog(new_cog)
	
	for cog : Cog in battle_node.cogs:
		if cog in new_cogs:
			cog.global_position = battle_node.get_cog_position(cog)
			battle_node.face_battle_center(cog)
			cog.fly_in(20.0, 0.0)
			cog.show()
		else:
			cog.move_to(battle_node.get_cog_position(cog)).finished.connect(func(): battle_node.face_battle_center(cog))
	
	battle_node.focus_cogs()
	battle_node.battle_cam.position.z += 2.0
	await manager.sleep(5.0)
	
