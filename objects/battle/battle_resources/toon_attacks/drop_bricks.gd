extends DropSmall

const HIT_RANGE := Vector2i(2, 7)
const PITCH_INCREASE := 0.1

var hit_count: Dictionary[Cog, int] = {}


func action() -> void:
	var hits := RandomService.randi_range_channel('true_random', HIT_RANGE.x, HIT_RANGE.y)
	var hit_order: Array[Cog] = []
	for i in hits:
		hit_order.append(RandomService.array_pick_random('true_random', targets))
	
	for cog in targets:
		hit_count[cog] = 1
	
	var button: Node3D
	if not skip_button_movie:
		battle_node.focus_character(user)
		user.set_animation('press-button')
		# Place button in hand
		button = load('res://models/props/gags/button/toon_button.tscn').instantiate()
		user.toon.left_hand_bone.add_child(button)
		
		# Wait for button press
		await manager.sleep(2.3)
		AudioManager.play_sound(load('res://audio/sfx/battle/gags/AA_trigger_box.ogg'))
		await manager.sleep(0.2)
	
	user.toon.hide()
	battle_node.focus_cogs()
	battle_node.battle_cam.position.z += 1
	
	for i in hit_order.size():
		var hit_tween := do_hit(hit_order.pop_back(), i)
		if i == hits - 1:
			await hit_tween.finished
		else:
			await Task.delay(1.0)
	
	await manager.check_pulses(targets)
	
	if button: button.queue_free()
	user.toon.show()

func do_hit(cog: Cog, index: int) -> Tween:
	var prop: Node3D = model.instantiate()
	var shadow = load('res://objects/misc/drop_shadow/drop_shadow.tscn').instantiate()
	cog.body.add_child(shadow)
	shadow.position.y += 0.05
	shadow.scale = Vector3(0.1, 0.1, 0.1)
	
	var hit_tween := create_tween()
	hit_tween.tween_callback(AudioManager.play_sound.bind(load('res://audio/sfx/battle/gags/drop/incoming_whistleALT.ogg')))
	hit_tween.tween_property(shadow, 'scale', Vector3(1, 1, 1) * shadow_scale, 2.0)
	hit_tween.tween_callback(
		func():
			cog.body.add_child(prop)
			prop.global_position = cog.body.head_bone.global_position
			prop.position.y -= (1.0 if cog.dna.suit == CogDNA.SuitType.SUIT_C else 2.0)
			prop.get_node('AnimationPlayer').play('drop')
	)
	hit_tween.tween_callback(shadow.queue_free)
	hit_tween.tween_callback(
	func():
		AudioManager.play_sound(sfx_hit).pitch_scale = 1.0 + (PITCH_INCREASE * index)
		manager.affect_target(cog, damage * hit_count[cog])
		apply_debuff(cog, damage * hit_count[cog])
		hit_count[cog] += 1
	)
	hit_tween.tween_callback(cog.set_animation.bind('anvil-drop'))
	hit_tween.tween_callback(cog.animator_seek.bind(0.0))
	hit_tween.tween_interval(4.0)
	hit_tween.tween_callback(prop.queue_free)
	hit_tween.finished.connect(hit_tween.kill)
	
	return hit_tween

func get_store_summary() -> String:
	var summary := "Hits a random Cog 2-7 times.\n" + get_stats()
	return summary
