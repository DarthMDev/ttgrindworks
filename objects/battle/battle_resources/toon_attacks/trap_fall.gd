extends GagTrap
class_name TrapFall

@export var model: PackedScene
@export var sfx: AudioStream

enum TrapType {
	SAND,
	DOOR,
	HOLE,
}
@export var trap_type := TrapType.SAND

var prop: Node3D

func action():
	var target = targets[0]
	user = Util.get_player()
	
	if target.trap or (target.lured and user.trap_needs_lure):
		return
	
	manager.s_focus_char.emit(user)
	user.set_animation('button_press')
	user.face_position(target.global_position)
	
	# Place button in hand
	var button = load('res://models/props/gags/button/toon_button.tscn').instantiate()
	user.toon.left_hand_bone.add_child(button)
	
	await manager.sleep(2.3)
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/AA_trigger_box.ogg"))
	
	await manager.sleep(0.5)
	battle_node.focus_cogs()
	battle_node.battle_cam.position.x = target.position.x
	battle_node.battle_cam.look_at(target.global_position)
	
	prop = model.instantiate()
	target.add_child(prop)
	prop.position = Vector3(0, 0.05, Globals.SUIT_LURE_DISTANCE)
	prop.scale = Vector3(.01, .01, .01)
	
	# Grow prop
	var prop_tween: Tween = prop.create_tween()
	prop_tween.set_trans(Tween.TRANS_ELASTIC)
	if trap_type == TrapType.HOLE:
		prop_tween.tween_property(prop, 'scale', Vector3(1.25, 1.25, 1.25), 1.0)
	else:
		prop_tween.tween_property(prop, 'scale', Vector3(.75, .75, .75), 1.0)
	
	if sfx:
		AudioManager.play_snippet(sfx,0.0,1.0)
	
	await prop_tween.finished
	prop_tween.kill()
	
	target.trap = self
	baked_crit_chance = manager.get_crit_chance(self)
	print("Trap: Baking crit chance to %s" % baked_crit_chance)
	
	# Finish setup
	await manager.sleep(0.5)
	button.queue_free()

	apply_trap_effect(target)

	# For detective hat item
	if not user.trap_needs_lure and target.lured:
		manager.force_unlure(target)
		await activate()

func activate():
	s_activate.emit()
	var target = targets[0]
	target.get_node('Body').position = Vector3(0, 0, 2)
	
	set_camera_angle(camera_angles['SIDE_RIGHT'])
	
	# Unique sink/fall
	match trap_type:
		TrapType.SAND:
			target.set_animation('flailing')
			AudioManager.play_sound(sfx)
			var sink_tween : Tween = target.create_tween()
			sink_tween.set_trans(Tween.TRANS_QUAD)
			sink_tween.tween_property(target.get_node('Body'), 'position:y', -5.0, 2.5)
			await sink_tween.finished
			sink_tween.kill()
		_:
			look_down(target)
			await manager.sleep(1.0)
			if trap_type == TrapType.DOOR:
				var door_mesh: MeshInstance3D = prop.get_node('trapdoor/Skeleton3D/TheTrapdoor')
				var new_mat := StandardMaterial3D.new()
				new_mat.albedo_color = Color.BLACK
				door_mesh.set_surface_override_material(0,new_mat)
				AudioManager.play_sound(sfx)
			await manager.sleep(1.0)
			target.animator.seek(1.2)
			target.animator.play()
			var fall_tween: Tween = target.create_tween()
			fall_tween.tween_property(target.get_node('Body'), 'position:y', -10.0, 0.5)
			if trap_type == TrapType.HOLE:
				AudioManager.play_sound(sfx).seek(2.35)
			await fall_tween.finished
			fall_tween.kill()
	
	prop.queue_free()
	target.set_animation('slip-forward')
	target.get_node('Body').position.y += 50.0
	var flop_tween : Tween = target.create_tween()
	flop_tween.tween_property(target.get_node('Body'), 'position:y', 0.0, 0.65)
	await flop_tween.finished
	flop_tween.kill()
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/trap/Toon_bodyfall_synergy.ogg"))
	if activating_lure:
		activating_lure.current_activating_trap = self
	
	if not get_immunity(target):
		manager.affect_target(target, damage)
		apply_extra_knockback(target)
	else:
		manager.battle_text(target, "IMMUNE")
	
	if activating_lure:
		activating_lure.current_activating_trap = null
	
	await target.animator.animation_finished
	target.set_animation('walk')
	var walk_tween: Tween = target.create_tween()
	walk_tween.tween_property(target.get_node('Body'), 'position:z', 0.0, 0.5)
	await walk_tween.finished
	walk_tween.kill()
	target.set_animation('neutral')
	
	target.trap = null
	
	await manager.check_pulses(targets)
	
	s_trap.emit()

# Works in tandem with trap door to create an animation effect
func look_down(target: Cog):
	target.set_animation('flailing')
	var look_tween: Tween = target.create_tween()
	look_tween.tween_method(target.animator.seek, 0.0, 0.6, 0.6)
	look_tween.tween_method(target.animator.seek, 0.6, 0.0, 0.6)
	await look_tween.finished
	look_tween.kill()
	target.animator.pause()
