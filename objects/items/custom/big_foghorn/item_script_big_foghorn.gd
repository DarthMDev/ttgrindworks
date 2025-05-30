extends ItemScriptActive

const MEGAPHONE := preload("res://models/props/gags/megaphone/megaphone.tscn")
const SFX_WINDUP := preload("res://audio/sfx/battle/gags/sound/mailbox_full_wobble.ogg")
const SFX_BLAST := preload("res://audio/sfx/battle/gags/sound/SZ_DD_foghorn.ogg")
const TREASURE_CHEST := "res://objects/interactables/treasure_chest/treasure_chest.tscn"
const BATTLE_CLEAR_POOL := "res://objects/items/pools/battle_clears.tres"

func use() -> void:
	var player := Util.get_player()
	var battles := get_all_battles()
	if not player.is_on_floor() or battles.is_empty():
		cancel_use()
		return
	
	var tween := make_tween(player, battles)
	await tween.finished
	tween.kill()
	player.state = Player.PlayerState.WALK

func make_tween(player : Player, battles : Array[BattleNode]) -> Tween:
	var megaphone := MEGAPHONE.instantiate()
	var foghorn := item.model.instantiate()
	
	# Add gag to megaphone
	megaphone.add_child(foghorn)
	# Transform the model
	foghorn.position = Vector3(1.067, 0.213, -1.631)
	foghorn.rotation_degrees = Vector3(0.1, 147.7, 81.8)
	foghorn.scale = Vector3.ONE * 0.475
	
	player.toon.right_hand_bone.add_child(megaphone)
	player.state = Player.PlayerState.STOPPED
	
	var tween := create_tween()
	tween.tween_callback(player.set_animation.bind('shout'))
	tween.tween_interval(1.0)
	tween.tween_callback(AudioManager.play_sound.bind(SFX_WINDUP))
	tween.tween_interval(1.4)
	tween.tween_callback(foghorn.get_node('AnimationPlayer').play.bind('sound'))
	tween.tween_callback(AudioManager.play_sound.bind(SFX_BLAST))
	tween.tween_callback(shake_camera.bind(player.camera.camera, 3.0, 0.1))
	tween.tween_callback(destroy_battles.bind(battles))
	tween.tween_interval(3.0)
	
	tween.finished.connect(megaphone.queue_free)
	
	return tween

func destroy_battles(battles : Array[BattleNode]) -> void:
	for battle in battles:
		destroy_battle(battle)

func get_all_battles() -> Array[BattleNode]:
	var node: Node
	if is_instance_valid(Util.floor_manager):
		node = Util.floor_manager.get_current_room()
	else:
		node = SceneLoader
	return search_node(node)

func search_node(node : Node) -> Array[BattleNode]:
	var battles : Array[BattleNode] = []
	for child in node.get_children():
		if child is BattleNode:
			if child.monitoring and not child.override_intro:
				battles.append(child)
		else:
			battles.append_array(search_node(child))
	return battles

func destroy_battle(battle : BattleNode) -> void:
	for cog in battle.cogs:
		BattleService.battle_participant_died(cog)
		cog.explode()
	
	var chest : TreasureChest = load(TREASURE_CHEST).instantiate()
	if Util.get_player().better_battle_rewards:
		chest.item_pool = ItemService.PROGRESSIVE_POOL
		Util.get_player().boost_queue.queue_text("Bounty!", Color.GREEN)
	else:
		chest.item_pool = load(BATTLE_CLEAR_POOL)
	battle.add_child(chest)
	chest.reparent(Util.floor_manager)
	battle.s_battle_end.emit()
	battle.set_monitoring.call_deferred(false)
	await Task.delay(10.0)
	battle.queue_free()


func shake_camera(cam : Camera3D, time : float, offset : float, taper := true, x := true, y := true, z := true) -> void:
	var base_pos := cam.global_position
	var shaking := true
	
	var timer := get_tree().create_timer(time)
	
	while shaking:
		await Util.s_process_frame
		var new_offset : float
		if taper:
			new_offset = offset * timer.time_left/time
		else:
			new_offset = offset
		if x:
			cam.global_position.x = base_pos.x + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if y:
			cam.global_position.y = base_pos.y + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if z:
			cam.global_position.z = base_pos.z + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		
		if timer.time_left <= 0:
			shaking = false
