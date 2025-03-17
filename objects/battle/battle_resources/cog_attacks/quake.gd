extends CogAttack
class_name Quake

enum AnimType {
	JUMP,
	STOMP
}
@export var anim_type := AnimType.JUMP


func action() -> void:
	# Setup
	var target : Player = targets[0]
	user.face_position(target.global_position)
	
	# Do animation
	manager.s_focus_char.emit(user)
	if anim_type == AnimType.JUMP:
		user.set_animation('jump')
	else:
		user.set_animation('stomp')
	await manager.sleep(1.75)
	
	# Roll for accuracy
	manager.s_focus_char.emit(targets[0])
	var hit := manager.roll_for_accuracy(self)
	
	# Affect toon. Or don't
	var anim := ''
	if hit:
		anim = 'slip_forwards'
		manager.affect_target(target, damage)
	else:
		manager.battle_text(target,"MISSED")
		anim = 'happy'
	
	# Play animation (twice)
	for i in 2:
		target.set_animation(anim)
		await manager.barrier(target.animator.animation_finished, 5.0)

	await manager.check_pulses(targets)
