extends ItemScriptActive

var player: Player:
	get: return Util.get_player()

var hypno_reference: ItemAccessory:
	get: return load("res://objects/items/custom/super_hypno/super_hypno_placement.tres")

func validate_use() -> bool:
	return not all_cogs_lured(BattleService.ongoing_battle)

func use() -> void:
	var battle := BattleService.ongoing_battle

	BattleService.ongoing_battle.battle_ui.cog_panels.reset(0)
	await cutscene(battle)
	BattleService.ongoing_battle.battle_ui.cog_panels.assign_cogs(BattleService.ongoing_battle.cogs)

func cutscene(battle: BattleManager) -> void:
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(true)
		
	battle.battle_ui.visible = false
	
	var cogs := battle.cogs
	var battle_node := battle.battle_node
	for cog: Cog in cogs.duplicate(true):
		if cog.lured: cogs.erase(cog)
	
	var prop: Node3D
	prop = load("res://models/props/gags/hypno_goggles/hypno_goggles_v2.tscn").instantiate()
	player.toon.glasses_node.add_child(prop)
	
	# Place accessory
	var placement := hypno_reference.get_placement(hypno_reference, player.toon.toon_dna)
	prop.position = placement.position
	prop.rotation_degrees = placement.rotation
	prop.scale = placement.scale
	
	player.set_animation('hypnotize')
	battle_node.focus_character(player)
	
	await Task.delay(0.5)
	AudioManager.play_sound(load('res://audio/sfx/battle/gags/lure/TL_hypnotize.ogg'))
	
	await Task.delay(0.75)
	battle_node.focus_cogs()
	
	for cog in cogs:
		cog.set_animation('hypnotize')
	await Task.delay(1.0)
	
	var walk_tween := create_tween().set_parallel()
	walk_tween.tween_property(battle_node.battle_cam, 'position:z', battle_node.battle_cam.position.z + Globals.SUIT_LURE_DISTANCE, 2.0)
	for cog in cogs:
		walk_tween.tween_property(cog.get_node('Body'), 'position:z', Globals.SUIT_LURE_DISTANCE, 2.0)
	await walk_tween.finished
	walk_tween.kill()
	
	# Now await their trap OR just lure the cog
	var barrier_turn := SignalBarrier.new()
	barrier_turn._barrier_type = SignalBarrier.BarrierType.ALL
	var trap_gags = []
	for cog in cogs:
		if cog.trap:
			trap_gags.append(cog.trap)
			cog.trap.activating_lure = get_reference_lure()
			barrier_turn.append(cog.trap.s_trap)
			cog.trap.activate()
		else:
			apply_lure(cog)
	if not barrier_turn._signal_arr.is_empty():
		await battle.barrier(barrier_turn.s_complete, 15.0)

	battle.battle_ui.visible = true
	Util.get_player().toon.show()
	battle.battle_node.focus_character(battle.battle_node)
	
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(false)
	
	prop.queue_free()

func all_cogs_lured(battle: BattleManager) -> bool:
	for cog in battle.cogs:
		if not cog.lured:
			return false
	return true

func apply_lure(cog: Cog) -> void:
	var lure := StatusLured.new()
	lure.lure_type = StatusLured.LureType.STUN
	lure.rounds = 1
	lure.target = cog
	lure.knockback_effect = get_knockback()
	lure.quality = StatusEffect.EffectQuality.NEGATIVE
	lure.icon = load('res://ui_assets/battle/gags/inventory_hypno_goggles.png')
	BattleService.ongoing_battle.add_status_effect(lure)

## Should return the knockback of the highest unlocked Lure Gag
func get_knockback() -> int:
	return get_reference_lure().lure_effect.knockback_effect

func get_reference_lure() -> GagLure:
	var stats := player.stats
	var highest_lure: GagLure = stats.character.gag_loadout.get_track_of_name('Lure').gags[stats.gags_unlocked['Lure'] - 1]
	return highest_lure
