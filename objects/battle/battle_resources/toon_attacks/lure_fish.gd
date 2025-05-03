extends GagLure
class_name LureFish

@export var override_mat: StandardMaterial3D


func action():
	set_camera_angle('SIDE_RIGHT')
	var target: Cog = targets[0]
	if target.lured:
		return
	user.face_position(target.global_position)
	
	var rod = load("res://models/props/gags/fishing_rod/fishing_rod.tscn").instantiate()
	var dollar = load("res://models/props/gags/fishing_rod/dollar_bill.tscn").instantiate()
	if override_mat:
		dollar.get_node("dollar/Skeleton3D/dollar1").set_surface_override_material(0, override_mat)
	user.toon.right_hand_bone.add_child(rod)
	
	battle_node.add_child(dollar)
	dollar.rotation_degrees.y += 180.0
	dollar.global_position = target.to_global(Vector3(0, 0.1, 3.25))
	dollar.scale = Vector3.ONE * 0.35
	
	# Animate
	user.set_animation('bait')
	user.animator.animation_finished.connect(func(_x=null): user.set_animation("lured"), CONNECT_ONE_SHOT)
	rod.get_node('AnimationPlayer').play('cast')
	dollar.get_node('AnimationPlayer').play('cast')
	
	# Play sfx
	await manager.sleep(0.5)
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/lure/TL_fishing_pole.ogg"))
	
	await manager.sleep(2.5)

	dollar.get_node('AnimationPlayer').speed_scale = (0.7 / 2.0)
	var dollar_move_seq := Sequence.new([
		Wait.new(2.1),
		LerpProperty.new(dollar, ^"global_position", 0.2, Util.get_player().to_global(Vector3(0, 3.5, -1.5))),
		Func.new(dollar.queue_free),
	]).as_tween(manager)

	# Roll for accuracy
	var hit := manager.roll_for_accuracy(self) and not get_immunity(target)
	
	# If hit, make cog reach for dollar
	if hit:
		target.set_animation('walknreach')
		manager.battle_text(target, "Stunned!", BattleText.colors.orange[0], BattleText.colors.orange[1])
		await target.animator.animation_finished
		if target.trap:
			trap_gags.append(target.trap)
			target.trap.activating_lure = self
			await target.trap.activate()
		else:
			apply_lure(target)
	else:
		manager.battle_text(target,"IMMUNE")
		await user.animator.animation_finished

	if dollar_move_seq.is_running():
		await dollar_move_seq.finished

	rod.queue_free()
	if target.lured:
		target.set_animation('lured')
