extends CogAttack

const CALCULATOR := preload('res://models/props/cog_props/calculator/calculator.glb')
const PARTICLES := preload('res://objects/battle/effects/tabulate/tabulate.tscn')
const SFX := preload("res://audio/sfx/battle/cogs/attacks/SA_audit.ogg")
const STAT_BOOST := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")

const BoostNums := {
	'damage': -0.3,
	'defense': -0.2,
	'luck': -0.3,
	'evasiveness': -0.3,
}

@export var play_sound := false

func action():
	var target = targets[0]
	user.face_position(target.global_position)
	var calculator: Node3D = CALCULATOR.instantiate()
	user.body.left_hand_bone.add_child(calculator)
	calculator.rotation_degrees = Vector3(-60, 45, 130)
	user.set_animation('phone')
	manager.s_focus_char.emit(user)
	
	await manager.sleep(2.0)
	# Start particles
	var particles = PARTICLES.instantiate()
	calculator.add_child(particles)
	particles.position.y = 3.0
	particles.global_position = calculator.global_position
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.gravity = particle_dir * 9.8
	particles.lifetime = sqrt(2.0 * particles.global_position.distance_to(target.head_node.global_position) / 9.8)

	manager.s_focus_char.emit(target)

	# Play sound
	await manager.sleep(0.4)
	if play_sound:
		AudioManager.play_sound(SFX)
	
	target.set_animation('conked')
	apply_debuff()
	
	await manager.sleep(2.0)
	particles.emitting = false
	
	await user.animator.animation_finished
	calculator.queue_free()
	
	await manager.check_pulses(targets)

func apply_debuff() -> void:
	var new_debuff := STAT_BOOST.duplicate(true)
	new_debuff.target = targets[0]
	new_debuff.rounds = 1
	new_debuff.quality = StatusEffect.EffectQuality.NEGATIVE
	new_debuff.stat = BoostNums.keys().pick_random()
	new_debuff.boost = BoostNums[new_debuff.stat]
	manager.add_status_effect(new_debuff)
	manager.battle_text(targets[0], "%s Down!" % (new_debuff.stat[0] + new_debuff.stat.substr(1)), BattleText.colors.orange[0], BattleText.colors.orange[1])
