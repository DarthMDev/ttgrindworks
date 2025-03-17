extends CogAttack
class_name ThrowPaper

# Config
@export var prop : PackedScene
@export var wait_time := 3.2
@export var custom_method : String

# Locals
var held_prop : Node3D
var hit : bool

func action():
	hit = manager.roll_for_accuracy(self)
	user.face_position(targets[0].global_position)
	# Hold the prop
	if prop: 
		held_prop = prop.instantiate()
	user.body.right_hand_bone.add_child(held_prop)
	user.set_animation('throw-paper')
	
	
	if has_method(custom_method):
		await Callable(self,custom_method).call()
	
	if is_instance_valid(held_prop):
		held_prop.queue_free()

func pink_slip():
	manager.s_focus_char.emit(user)
	held_prop.rotation_degrees = Vector3(90.0,180.0,90.0)
	held_prop.scale*=7.5
	var target = targets[0]
	
	
	if hit:
		await manager.sleep(wait_time-0.2)
		target.set_animation('happy')
		await manager.sleep(0.2)
	else:
		await manager.sleep(wait_time)
	
	held_prop.top_level = true
	var throw_tween : Tween = held_prop.create_tween()
	throw_tween.set_parallel(true)
	throw_tween.tween_property(held_prop,'global_position',target.global_position,0.8)
	throw_tween.tween_property(held_prop,'rotation_degrees',Vector3(0.0,-180.0,-180.0),0.5)
	AudioManager.play_snippet(load("res://audio/sfx/battle/cogs/attacks/SA_pink_slip.ogg"),0.0,1.0)
	manager.s_focus_char.emit(target)
	
	# When missed, jump late
	if not hit:
		target.set_animation('happy')
		manager.battle_text(target,'MISSED')
	
	await throw_tween.finished
	if hit:
		manager.affect_target(target, damage)
		target.set_animation('slip_forwards')
	
	await manager.barrier(target.animator.animation_finished, 4.0)
	
	await manager.check_pulses(targets)


func eviction_notice() -> void:
	held_prop.position = Vector3(1.477, -0.442, -0.83)
	held_prop.rotation_degrees = Vector3(-27.2, 176.1, -36.3)
	
	var player : Player = targets[0]
	battle_node.focus_character(user)
	
	if not hit:
		var stagger := 0.2
		await manager.sleep(wait_time - stagger)
		player.set_animation('happy')
		await manager.sleep(stagger)
	else:
		await manager.sleep(wait_time)
	
	held_prop.reparent(battle_node)
	held_prop.global_position.y = player.global_position.y + 1.5
	held_prop.look_at(player.global_position)
	
	var forward_vec := held_prop.global_transform.basis.z.normalized()
	var distance := -held_prop.global_position.distance_to(player.global_position)

	if not hit:
		distance -= 2.0
	
	var destination := held_prop.global_position + (forward_vec*distance)
	
	
	var throw_tween : Tween = held_prop.create_tween()
	throw_tween.tween_property(held_prop,'global_position', destination, 0.6)
	throw_tween.finished.connect(
		func():
			throw_tween.kill()
			held_prop.queue_free()
			if hit:
				player.set_animation("cringe")
				manager.affect_target(player, damage)
	)
	
	
	battle_node.focus_character(player)
	
	if not hit:
		manager.battle_text(player, "MISSED")
	
	await manager.barrier(player.animator.animation_finished, 3.0)
