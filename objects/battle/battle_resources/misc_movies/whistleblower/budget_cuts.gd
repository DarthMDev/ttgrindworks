extends CogAttack

const STAMP_PAD := preload('res://models/props/cog_props/rubber_stamp/stamp_pad.tscn')
const STAMP := preload('res://models/props/cog_props/rubber_stamp/rubber_stamp.glb')
const STAMP_TEXT := preload("res://models/props/cog_props/rubber_stamp/stamp_text.tscn")
const SFX_STAMP := preload('res://audio/sfx/battle/cogs/attacks/SA_rubber_stamp.ogg')
const SFX_TOON_HIT := preload("res://audio/sfx/battle/cogs/attacks/special/tt_s_ara_cfg_toonHit.ogg")
const STATUS_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_budget_cuts.tres')

var track: String = ""

func action() -> void:
	var cog: Cog = user
	var player: Player = targets[0]
	
	# CREATE PROPS
	var pad := STAMP_PAD.instantiate()
	cog.body.left_hand_bone.add_child(pad)
	pad.position = Vector3(-0.93, 0.803, -0.267)
	pad.rotation_degrees = Vector3(-8.6, -94.5, -82)
	var stamp := STAMP.instantiate()
	cog.body.right_hand_bone.add_child(stamp)
	stamp.position = Vector3(-0.669, 0.295, -0.692)
	stamp.rotation_degrees = Vector3(-85, -34, 125)
	var stamp_text : Label3D = STAMP_TEXT.instantiate()
	cog.add_child(stamp_text)
	stamp_text.hide()
	
	# MOVIE START
	var movie := manager.create_tween()
	
	# Focus Cog
	movie.tween_callback(cog.face_position.bind(player.global_position))
	movie.tween_callback(battle_node.focus_character.bind(cog))
	movie.tween_callback(cog.set_animation.bind('rubber-stamp'))
	movie.tween_interval(1.6)
	
	# Play sound
	movie.tween_callback(AudioManager.play_sound.bind(SFX_STAMP))
	movie.tween_interval(1.5)
	
	# Launch Stamp Text
	movie.tween_callback(
		func():
			stamp_text.global_position = cog.body.right_hand_bone.global_position
			stamp_text.look_at(player.head_node.global_position)
			stamp_text.show()
	)
	movie.tween_property(stamp_text, 'global_position', player.head_node.global_position, 0.75)
	
	# Show player getting hit
	movie.parallel().tween_callback(battle_node.focus_character.bind(player)).set_delay(0.35)
	movie.tween_callback(apply_status_effect)
	movie.tween_callback(stamp_text.queue_free)
	movie.tween_callback(player.set_animation.bind('cringe'))
	movie.tween_callback(manager.battle_text.bind(player, "Budget Cuts!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
	movie.tween_callback(AudioManager.play_sound.bind(SFX_TOON_HIT))
	movie.tween_interval(3.0)
	
	# Cleanup
	await movie.finished
	movie.kill()
	stamp.queue_free()
	pad.queue_free()

func apply_status_effect() -> void:
	var effect := STATUS_EFFECT.duplicate(true)
	if targets[0].gags_cost_beans:
		effect.penalty = 1
	effect.target = targets[0]
	effect.track_name = track
	manager.add_status_effect(effect)
