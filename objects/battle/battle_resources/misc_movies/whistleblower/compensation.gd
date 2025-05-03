extends CogAttack

const BOOST_PHRASES: Array[String] = [
	"My hard work has been rewarded.",
	"A much needed pick-me-up.",
	"This will enhance my performance.",
	"Finally, my bonus has arrived.",
	"No pain no gain it seems.",
]
const STAT_BOOST := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_workers_comp.tres')
const SFX_WHISTLE := preload("res://audio/sfx/battle/gags/sound/AA_sound_whistle.ogg")


func action() -> void:
	# FAILSAFE
	for i in range(targets.size() - 1, -1, -1):
		var target = targets[i]
		if not target or target.stats.hp <= 0:
			targets.remove_at(i)
	if targets.is_empty():
		manager.show_action_name("", "")
		return
	
	var cog: Cog = user
	
	# MOVIE START
	var movie := manager.create_tween()
	
	# Focus user
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('compensation'))
	movie.tween_interval(0.4)
	movie.tween_callback(AudioManager.play_sound.bind(SFX_WHISTLE))
	movie.tween_interval(1.6)
	
	# Focus Cogs
	movie.tween_callback(battle_node.focus_cogs)
	for target in targets:
		movie.tween_callback(target.set_animation.bind('buffed'))
		movie.tween_callback(target.speak.bind(RandomService.array_pick_random('true_random', BOOST_PHRASES)))
		movie.tween_callback(create_status_effects.bind(target))
	
	movie.tween_interval(3.0)
	
	await movie.finished

const BOOST_AMOUNT := 1.25
func create_status_effects(target: Cog) -> void:
	var stat_boost := STAT_BOOST.duplicate()
	stat_boost.boost = BOOST_AMOUNT
	stat_boost.target = target
	manager.add_status_effect(stat_boost)
