extends ActionScript
class_name GoonAttack


const ACTION_NAME := "Ex post facto Law!"
const ACTION_SUMMARY := "The Goon changes the Cog's gag immunities!"

func action() -> void:
	# Get our necessary dependencies
	var goon: Goon = user
	var focus_node: Node3D = goon.get_node('FocusNode')
	var cogs: Array[Cog] = manager.cogs
	
	# Play alarm sound at low speed
	var audio_player := AudioManager.play_snippet(goon.SFX_ALERT, 0.0, 2.2)
	audio_player.pitch_scale = 0.85
	
	if manager.cogs.is_empty():
		return
	
	# Start movie
	var movie := manager.create_tween()
	
	# Focus Goon
	movie.tween_callback(goon.set_animation.bind('alarm'))
	movie.tween_callback(battle_node.focus_character.bind(focus_node))
	movie.tween_callback(manager.show_action_name.bind(ACTION_NAME,ACTION_SUMMARY))
	movie.tween_interval(1.4)
	movie.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/misc/CHQ_SOS_cage_land.ogg")))
	movie.tween_interval(0.6)
	
	# Focus Cogs
	movie.tween_callback(battle_node.focus_cogs)
	movie.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/battle/cogs/attacks/special/LB_camera_shutter_2.ogg"), -10.0))
	for cog in cogs:
		movie.tween_callback(swap_track.bind(get_immunity(cog)))
		movie.tween_callback(cog.set_animation.bind('soak'))
	movie.tween_interval(1.0)
	for cog in cogs:
		movie.tween_callback(cog.animator.set_speed_scale.bind(-1.0))
	movie.tween_interval(1.0)
	for cog in cogs:
		movie.tween_callback(cog.animator.set_speed_scale.bind(1.0))
		movie.tween_callback(cog.set_animation.bind('neutral'))
	movie.tween_interval(1.0)
	movie.tween_callback(goon.set_animation.bind('neutral'))
	await movie.finished
	movie.kill()

func get_immunity(cog : Cog) -> StatusEffectGagImmunity:
	var effects := manager.get_statuses_for_target(cog)
	for effect in effects:
		if effect is StatusEffectGagImmunity:
			return effect
	return null

func swap_track(effect: StatusEffectGagImmunity) -> void:
	effect.set_track(Util.get_player().stats.character.gag_loadout.loadout.pick_random())
