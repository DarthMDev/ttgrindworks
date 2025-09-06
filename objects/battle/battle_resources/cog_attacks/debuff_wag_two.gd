extends CogAttack
class_name DebuffWagTwo

const STAT_BOOST := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_budget_cuts.tres')
var type = 1
var mark = false # not needed but meh more oftf bloat 🐱‍🏍
var marks = 0
var debuff_msg = "Minus Gag Points"
func action():
	# Begin
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
	else: manager.battle_text(target, "Minus Gag Points", BattleText.colors.orange[0], BattleText.colors.orange[1])
	particles.emitting = false
	
	# Cleanup
	await manager.barrier(target.animator.animation_finished, 4.0)
	
	await manager.check_pulses(targets)
	
	particles.queue_free()

func create_debuff(player : Player) -> StatBoost:
		var effect := STAT_BOOST.duplicate()
		effect.target = player
		effect.rounds = 1
		var tracks := Util.get_player().stats.gag_regeneration.keys()
		var track = RandomService.array_pick_random('true_random', tracks)
		effect.track_name = track
		var stats : PlayerStats = Util.get_player().stats
		for trackname in stats.gags_unlocked:
			stats.gag_balance[trackname] -= max(3,roundi(stats.gag_regeneration[trackname] * 1.5) )
		return effect

	
