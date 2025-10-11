extends ItemScript

const HIT_PERCENT := 0.2
const HIT_CHANCE := 0.25
const COG_HIT_CHANCE := 0.65
const METEOR := preload("res://objects/items/custom/toonosaur_hat/meteor.tscn")
const EXPLOSION := preload("res://objects/items/custom/toonosaur_hat/meteor_explosion.tscn")
const SFX_DROP := "res://audio/sfx/battle/gags/drop/incoming_whistleALT.ogg"
const SFX_HIT := "res://audio/sfx/battle/cogs/ENC_cogfall_apart.ogg"


func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_start)

func on_round_start(_actions: Array[BattleAction]) -> void:
	if randf() < Util.get_player().stats.get_luck_weighted_chance(HIT_CHANCE, HIT_CHANCE * 1.5, 2.0):
		queue_movie(BattleService.ongoing_battle)
	else:
		print("Toonosaur Hat did not hit :(")

func queue_movie(battle: BattleManager) -> void:
	var action := ActionScriptCallable.new()
	action.callable = battle_movie
	action.user = battle.battle_node
	if randf() < Util.get_player().stats.get_luck_weighted_chance(COG_HIT_CHANCE, 0.85, 2.0):
		action.targets = battle.cogs
	else:
		action.targets = [Util.get_player()]
	action.special_action_exclude = true
	battle.round_actions.insert(0, action)

func battle_movie() -> void:
	var manager := BattleService.ongoing_battle
	var battle_node := manager.battle_node
	var targets := manager.current_action.targets
	var damages_to_inflict: Array[int] = []
	var audio_player := AudioManager.play_sound(load(SFX_DROP))
	
	# Calculate our movie stuffs
	var meteor_pos := Vector3.ZERO
	for target in targets:
		meteor_pos += target.global_position
		var damage_value: int = maxi(floori(target.stats.max_hp * HIT_PERCENT), 1)
		if target is Cog:
			damage_value = maxi(damage_value, target.level * 3)
		damages_to_inflict.append(damage_value)
	meteor_pos /= targets.size()

	# Set cam angle
	if targets[0] is Player:
		var player: Player = targets[0]
		battle_node.focus_character(player, 6.0, 0)
	else:
		battle_node.focus_cogs()
		battle_node.battle_cam.position.z += 1
	
	# Oh yeah. It's meteor time
	var meteor := METEOR.instantiate()
	battle_node.add_child(meteor)
	meteor.global_position = meteor_pos
	meteor.position += Vector3(20.0, 20.0, 0.0)
	meteor.scale *= 4.0
	meteor.look_at(meteor_pos)
	await Task.delay(2.0)

	var tween := create_tween()
	tween.tween_property(meteor, 'global_position', meteor_pos, 0.4)
	await tween.finished
	tween.kill()
	meteor.queue_free()
	
	audio_player.queue_free()
	AudioManager.play_sound(load(SFX_HIT))
	
	var explosion := EXPLOSION.instantiate()
	battle_node.add_child(explosion)
	explosion.global_position = meteor_pos
	scale_explosion(explosion, float(targets.size()) + 1.0 )
	explosion.get_node('AnimationPlayer').play('explode_2')
	explosion.get_node('AnimationPlayer').animation_finished.connect(func(_anim): explosion.queue_free())
	
	Util.shake_camera(battle_node.battle_cam, 3.0, 0.6)
	for target in targets:
		if target is Cog:
			target.set_animation('squirt-small')
		elif target is Player:
			target.set_animation('cringe')
		manager.affect_target(target, damages_to_inflict[targets.find(target)])
	await Task.delay(4.5)
	
	await manager.check_pulses(targets)

func scale_explosion(explosion: Node3D, amount: float) -> void:
	
	explosion.scale *= amount
	
	for child in explosion.get_children():
		if child is GPUParticles3D:
			var process_material: ParticleProcessMaterial = child.process_material.duplicate(true)
			process_material.scale_min *= amount
			child.process_material = process_material
