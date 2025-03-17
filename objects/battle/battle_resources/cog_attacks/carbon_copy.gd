extends CogAttack
class_name CarbonCopy

## Sidesteps to create a copy of the Cog
## Both perform a different attack before the copy disappears
## DO NOT HAVE THIS AS A COG'S ONLY ATTACK thank you
func action() -> void:
	# Failsafe to avoid an infinite loop
	if user.dna.attacks.size() == 1:
		print("Can't use Carbon Copy if the Cog only has one attack")
		return
	
	# Allow a moment for the battle phrase to be read
	manager.s_focus_char.emit(user)
	await manager.sleep(3.0)
	
	# Create a copy of the cog in battle
	var copy: Cog = load('res://objects/cog/cog.tscn').instantiate()
	copy.dna = user.dna.duplicate()
	copy.stats = manager.battle_stats[user].duplicate()
	copy.level = user.level
	copy.skelecog = user.skelecog
	copy.skelecog_chance = 0
	copy.virtual_cog = user.virtual_cog
	manager.battle_node.add_child(copy)
	copy.stats.hp = user.stats.hp
	copy.update_health_light()
	copy.global_transform = user.global_transform
	
	# Add the copy to the battle
	copy.battle_start()
	manager.add_cog(copy,manager.cogs.find(user) + 1)

	if user.virtual_cog:
		copy.body.set_color(user.body.body_color)
	
	# Make copy sidestep left
	copy.set_animation('sidestep-left')
	
	# Wait for the Cog to be back on the ground in a neutral pose
	# Stop the animation, and adjust the copy's base position
	await manager.sleep(1.5)
	copy.set_animation('neutral')
	copy.body.position.x = -4.283
	var copy_global_pos: Vector3 = copy.body.global_position
	copy.body.position.x = 0.0
	copy.global_position = copy_global_pos
	copy.speak("...but together, we are strong.")
	manager.s_focus_char.emit(copy)
	await manager.sleep(3.0)
	
	# Determine if attack will hit
	var hit := manager.roll_for_accuracy(self)
	
	# Get another (non Carbon Copy) attack
	var new_attack: CogAttack
	while not new_attack or new_attack is CarbonCopy:
		new_attack = copy.get_attack()
		if hit: new_attack.accuracy = Globals.ACCURACY_GUARANTEE_HIT
		else: new_attack.accuracy = Globals.ACCURACY_GUARANTEE_MISS
	
	# Copy some necessary values over from this attack
	new_attack.manager = manager
	
	# Create a copy of that attack for the main user
	var user_attack := new_attack.duplicate()
	user_attack.user = user
	user_attack.manager = manager
	user_attack.targets = targets
	user_attack.accuracy = new_attack.accuracy
	
	# Do both attacks simultaneously
	new_attack.action()
	await user_attack.action()
	
	# Wait for an additional half second to avoid race conditions
	await manager.sleep(0.5)
