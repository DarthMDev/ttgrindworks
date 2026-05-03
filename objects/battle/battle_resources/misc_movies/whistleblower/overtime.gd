extends CogAttack

const STATUS_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_overtime.tres')

func action() -> void:
	var cog : Cog = user
	var target : Cog = targets[0]
	
	# MOVIE START
	var movie := manager.create_tween()
	
	# Focus user
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('speak'))
	movie.tween_callback(cog.face_position.bind(target.global_position))
	movie.tween_interval(3.0)
	
	# Focus target
	movie.tween_callback(battle_node.focus_character.bind(target))
	movie.tween_callback(target.speak.bind("Yes, ma'am..."))
	movie.tween_callback(apply_effect)
	movie.tween_callback(manager.battle_text.bind(target, "+1 Move!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
	movie.tween_interval(3.0)
	
	# Cleanup
	await movie.finished
	movie.kill()

func apply_effect() -> void:
	var effect := STATUS_EFFECT.duplicate(true)
	effect.target = targets[0]
	manager.add_status_effect(effect)
