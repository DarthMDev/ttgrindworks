extends CogAttack

const EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres')

var tracks : Array[Track] = []

func action() -> void:
	var cog : Cog = user
	
	# MOVIE START
	var movie := manager.create_tween()
	
	# Focus Cog
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('speak'))
	movie.tween_interval(3.0)
	
	# Add status effect
	movie.tween_callback(battle_node.focus_cogs)
	for target : Cog in targets:
		movie.tween_callback(target.body.flash.bind(Color.GREEN))
		for track in tracks:
			movie.tween_callback(add_effect.bind(target, track))
	
	await movie.finished
	movie.kill()

func add_effect(target : Cog, track : Track) -> void:
	var new_effect := EFFECT.duplicate(true)
	new_effect.target = target
	new_effect.rounds = 2
	new_effect.track = track
	manager.add_status_effect(new_effect)
