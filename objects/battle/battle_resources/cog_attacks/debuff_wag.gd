extends CogAttack
class_name DebuffWag

const STAT_BOOST := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres')
var type = 1
var mark = false # not needed but meh more oftf bloat 🐱‍🏍
var marks = 0
var debuff_msg = "MARK X"
func action():
	# Begin
	if mark:
		debuff_msg = debuff_msg + str(marks)
	user.set_animation('finger-wag')
	manager.s_focus_char.emit(user)
	var target = targets[0]
	user.face_position(target.global_position)
	
	# Start particles after pause
	await manager.sleep(1.2)
	var particles = load('res://objects/battle/effects/finger_wag/finger_wag.tscn').instantiate()
	user.add_child(particles)
	particles.global_position = user.body.right_index_bone.global_position
	var particle_dir = particles.global_position.direction_to(target.head_node.global_position)
	particles.process_material.gravity = particle_dir*9.8
	particles.lifetime = sqrt(2.0*particles.global_position.distance_to(target.head_node.global_position)/9.8)
	AudioManager.play_sound(load('res://audio/sfx/battle/cogs/attacks/SA_finger_wag.ogg'))
	
	# Additional pause
	await manager.sleep(0.75)
	manager.s_focus_char.emit(target)
	
	# Perfect accuracy
	manager.affect_target(target, damage)
	target.set_animation('slip_backward')
	manager.add_status_effect(create_debuff(Util.get_player()))

	
	# Stop particles after pause
	await manager.sleep(0.5)
	if mark: manager.battle_text(target, debuff_msg, BattleText.colors.orange[0], BattleText.colors.orange[1])
	else: manager.battle_text(target, "Hurry Sickness", BattleText.colors.orange[0], BattleText.colors.orange[1])
	particles.emitting = false
	
	# Cleanup
	await manager.barrier(target.animator.animation_finished, 4.0)
	
	await manager.check_pulses(targets)
	
	particles.queue_free()

func create_debuff(player : Player) -> StatBoost:
	if not mark:
		var effect := STAT_BOOST.duplicate()
		effect.quality = StatusEffect.EffectQuality.NEGATIVE
		effect.boost = 0.6
		effect.stat = 'damage'
		effect.target = player
		effect.rounds = 1
		effect.status_name = "Hurry Sickness"
		effect.force_no_combine = true
		return effect
	var effect := STAT_BOOST.duplicate()
	effect.quality = StatusEffect.EffectQuality.NEGATIVE
	effect.icon_color = Color.RED
	effect.boost = 1
	effect.stat = 'defense'
	effect.target = player
	effect.rounds = 0
	effect.special_description = "The next mark will result in minus %d%% max laff" % ((marks+1) * 10)
	#description = "At the end of round will attack and mark dealing %d%% of max laff in damage" % (mark_amount * 10)
	effect.status_name = debuff_msg
	effect.force_no_combine = true
	return effect
	
