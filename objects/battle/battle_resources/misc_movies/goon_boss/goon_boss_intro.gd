extends BattleStartMovie
class_name GoonBossIntro

const GOON_EYE_COLOR := Color("ffff44")
const SFX_LIGHT := preload("res://audio/sfx/objects/spotlight/LB_laser_beam_on_2.ogg")
const SFX_SPARK := preload("res://audio/sfx/battle/cogs/misc/LB_sparks_1.ogg")

var directory: Node3D
var goon: Goon

func _skip() -> void:
	super()
	if goon.alert_tween and goon.alert_tween.is_running():
		goon.alert_tween.kill()
		goon.audio_player.stop()
		goon.set_light_color(Color.WHITE)

func play() -> Tween:
	
	# Get our dependencies
	directory = battle_node.get_parent()
	var player := Util.get_player()
	goon = directory.goon
	
	## MOVIE START
	movie = create_tween()
	
	# Player walks in
	movie.tween_callback(set_camera_angle.bind('IntroCam'))
	movie.tween_callback(player.set_global_position.bind(get_char_position('StartPos')))
	movie.tween_callback(player.face_position.bind(get_char_position('WalkInPos')))
	movie.tween_callback(player.set_animation.bind('walk'))
	movie.tween_property(player,'global_position',get_char_position('WalkInPos'), 4.0)
	movie.set_trans(Tween.TRANS_QUAD)
	movie.parallel().tween_property(battle_node.battle_cam,'global_transform',get_camera_angle('IntroCam2'),3.9)
	movie.set_trans(Tween.TRANS_LINEAR)
	movie.tween_callback(player.set_animation.bind('neutral'))
	movie.tween_interval(1.0)
	
	# Goon activates
	movie.tween_callback(set_camera_angle.bind('GoonEyeCam'))
	movie.tween_interval(1.0)
	movie.tween_method(goon.set_eye_color,Color.WHITE,GOON_EYE_COLOR,1.0)
	movie.tween_interval(1.0)
	movie.tween_callback(player.face_position.bind(goon.global_position))
	
	# Goon awakens
	movie.tween_callback(set_camera_angle.bind('GoonAwaken1'))
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_callback(goon.recover)
	movie.parallel().tween_property(battle_node.battle_cam,'global_transform',get_camera_angle('GoonAwaken2'),3.0)
	movie.tween_interval(1.0)
	
	# Good light turns on
	movie.tween_callback(goon.set_animation.bind('neutral'))
	movie.tween_callback(goon.skeleton.reset_bone_poses)
	movie.tween_callback(set_camera_angle.bind('GoonLightActivate'))
	movie.tween_interval(0.5)
	movie.tween_callback(directory.elevator.close)
	movie.tween_callback(goon.play_sfx.bind(SFX_LIGHT))
	movie.tween_callback(goon.set_light_visible.bind(true))
	movie.tween_callback(player.set_animation.bind('cringe'))
	movie.tween_interval(2.0)
	
	# Goon's alarm trips
	movie.tween_callback(set_camera_angle.bind('GoonAwaken2'))
	movie.tween_interval(0.5)
	movie.tween_callback(goon.set_animation.bind('spin'))
	movie.tween_callback(goon.play_sfx.bind(goon.SFX_ALERT))
	movie.tween_method(goon.set_light_color, Color.WHITE, Color.RED, 0.5)
	movie.tween_interval(1.5)
	
	# Elevator opens
	movie.tween_interval(0.5)
	movie.set_trans(Tween.TRANS_LINEAR)
	movie.tween_callback(player.toon.anim_play_backwards.bind('walk'))
	movie.tween_property(player,'global_position', get_char_position('BackupPos'), 3.0)
	movie.parallel().tween_property(camera, 'global_transform', get_camera_angle('Elevator'), 2.5).set_delay(0.25)
	movie.parallel().tween_callback(goon.audio_player.stop).set_delay(1.0)
	
	var delay := 0.5
	movie.parallel().tween_callback(AudioManager.play_sound.bind(SFX_SPARK)).set_delay(delay)
	movie.parallel().tween_callback(focus_cog.speak.bind("Stop right there, Toon!")).set_delay(delay)
	for cog in battle_node.cogs:
		movie.parallel().tween_callback(cog.show).set_delay(delay)
		movie.parallel().tween_callback(cog.set_animation.bind('drop')).set_delay(delay)
		movie.parallel().tween_callback(cog.animator_seek.bind(3.0)).set_delay(delay)
		delay += 0.2
	
	movie.tween_callback(player.set_animation.bind('neutral'))
	movie.tween_interval(3.0)
	movie.tween_callback(start_music)
	movie.tween_callback(goon.set_animation.bind('neutral'))
	return movie

func set_camera_angle(angle: String) -> void:
	battle_node.battle_cam.global_transform = get_camera_angle(angle)

func get_char_position(pos: String) -> Vector3:
	return directory.get_char_position(pos)

func get_camera_angle(angle: String) -> Transform3D:
	return directory.get_camera_angle(angle)
