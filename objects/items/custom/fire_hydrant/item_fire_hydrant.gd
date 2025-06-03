extends ItemScriptActive

const HYDRANT := preload("res://models/props/gags/firehose/betterhydrant.tscn")
const DRENCHED := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_drenched.tres")

func use() -> void:
	if not is_instance_valid(BattleService.ongoing_battle):
		cancel_use()
		return
	
	BattleService.ongoing_battle.battle_ui.cog_panels.reset(0)
	await cutscene(BattleService.ongoing_battle.cogs)
	BattleService.ongoing_battle.battle_ui.cog_panels.assign_cogs(BattleService.ongoing_battle.cogs)

func cutscene(cogs : Array[Cog]) -> void:
	var battle := BattleService.ongoing_battle
	var battle_node := battle.battle_node
	
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(true)
		
	battle.battle_ui.visible = false
	Util.get_player().visible = false
	
	var hyd = HYDRANT.instantiate()
	
	battle_node.add_child(hyd)
	
	hyd.scale = Vector3(.4,.4,.4)
	hyd.position.z = 1.5
	hyd.rotation_degrees -= Vector3(0,180,0)
	hyd.scale.y = 0.01
	
	battle.battle_node.battle_cam.position -= Vector3(0, 3, 1)
	battle.battle_node.battle_cam.rotation_degrees += Vector3(35,0,0)
	
	var tween = hyd.create_tween().set_trans(Tween.TRANS_BACK).set_parallel()
	tween.tween_property(hyd, 'position:y', 0.0, 0.5)
	tween.tween_property(hyd, 'scale:y', 0.4, 0.5)
	
	await tween.finished
	tween.kill()
	
	await Task.delay(0.4)
	
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/squirt/firehose_spray.ogg"))
	
	for cog in cogs:
		var splash: Node3D = load('res://models/props/gags/water_splash/water_splash_untextured.tscn').instantiate()
		battle.add_child(splash)
		splash.global_position = hyd.get_node("Coupler").global_position
		splash.end.rotation_degrees = Vector3(0,0,-90)
		splash.spray(cog.head_node.global_position, 0.5)
		
		var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
		splat.modulate = Globals.SQUIRT_COLOR
		splat.set_text("SPLASH!")
		cog.head_node.add_child(splat)
		cog.set_animation('squirt-small')
		
		# Apply the drenched effect
		var drenched = DRENCHED.duplicate()
		drenched.target = cog
		drenched.boost = Util.get_player().stats.get_stat('squirt_defense_boost')
		BattleService.ongoing_battle.add_status_effect(drenched)
	
	await Task.delay(2.5)
	
	tween = hyd.create_tween().set_trans(Tween.TRANS_BACK).set_parallel().set_ease(Tween.EASE_IN)
	tween.tween_property(hyd, 'scale:y', 0.01, 0.5)
	tween.tween_property(hyd, 'position:y', -3.0, 0.1).set_delay(0.4)
	
	await tween.finished
	tween.kill()
		
	battle.battle_ui.visible = true
	Util.get_player().visible = true
	battle.battle_node.focus_character(battle.battle_node)
	
	if is_instance_valid(battle.battle_ui.timer):
		battle.battle_ui.timer.timer.set_paused(false)
