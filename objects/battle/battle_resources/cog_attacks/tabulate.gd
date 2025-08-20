extends CogAttack
class_name Tabulate

const CALCULATOR := preload('res://models/props/cog_props/calculator/calculator.glb')
const PARTICLES := preload('res://objects/battle/effects/tabulate/tabulate.tscn')
const SFX := preload("res://audio/sfx/battle/cogs/attacks/SA_audit.ogg")

## for stat boost status effects 
#My lazy ahh adding ts instead of making a new cog attack %5
const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
var foreman_attack_boost = 1.25
@export var play_sound := false
@export var textarr = ["Damage up boy", "OVERCHARGED"]

func action():
	self.accuracy = Globals.ACCURACY_GUARANTEE_HIT
	var hit := manager.roll_for_accuracy(self)
	if self.action_name == "Worker's Compensation": apply()
	if user.unstable == false:
		var target = targets[0]
		user.face_position(target.global_position)
		var calculator : Node3D = CALCULATOR.instantiate()
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
		particles.gravity = particle_dir*9.8
		particles.lifetime = sqrt(2.0*particles.global_position.distance_to(target.head_node.global_position)/9.8)
		#	tween.tween_callback(manager.battle_text.bind(cog, "Damage Up!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
		#tween.tween_interval(3.0)
		#
		
		# Play sound, nope
		await manager.sleep(0.4)
		if play_sound:
			if self.action_name != "Worker's Compensation":
				AudioManager.play_sound(SFX)
		
		manager.s_focus_char.emit(target)
		if hit:
			target.set_animation('conked')
			if user.foreman:
				var heal_amount = -0.8333
				if Util.floor_number > 5:
					heal_amount = -0.455
				elif Util.floor_number >= 8:
					heal_amount = 0.33
				manager.affect_target(target, target.stats.max_hp * heal_amount, true)
			else:
				manager.affect_target(target, damage)
		else:
			target.set_animation('sidestep_left')
			manager.battle_text(target,"MISSED")
		await manager.sleep(0.6) # Color('ff0000'), Color('7a0000')
		if self.action_name == "Worker's Compensation": manager.battle_text(target,"1.25x damage",Color('c77dff'), Color('5a189a'))
		await manager.sleep(2.0)
		particles.emitting = false
		
		await user.animator.animation_finished
		calculator.queue_free()
		
		
		await manager.check_pulses(targets)
	else:
		var target = targets[0]
		manager.s_focus_char.emit(user)
		user.set_animation('song-and-dance')
		await manager.sleep(0.8)
		if user.foreman:
				var heal_amount = -0.8333
				if Util.floor_number > 5:
					heal_amount = -0.455
				elif Util.floor_number >= 8:
					heal_amount = -0.29    #759
				manager.affect_target(target, target.stats.max_hp * heal_amount, true)
				await manager.sleep(0.6) # Color('ff0000'), Color('7a0000')
				if self.action_name == "Worker's Compensation": manager.battle_text(target,"1.25x damage",Color('c77dff'), Color('5a189a'))
		
		await user.animator.animation_finished
		
	
func apply():
		var new_boost := STAT_BOOST_REFERENCE.duplicate()
		new_boost.quality = StatusEffect.EffectQuality.POSITIVE
		new_boost.stat = "damage"
		new_boost.boost = foreman_attack_boost
		new_boost.rounds = -1
		new_boost.target = user
		manager.add_status_effect(new_boost)
