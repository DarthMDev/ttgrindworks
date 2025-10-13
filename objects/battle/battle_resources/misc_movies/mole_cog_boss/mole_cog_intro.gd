extends BattleStartMovie


const SFX_HIT := preload("res://audio/sfx/objects/moles/Mole_Stomp.ogg")
const SFX_FLYBACK := preload("res://audio/sfx/misc/tt_s_ara_mat_crash_glassBoing.ogg")
const SFX_JUMP := preload("res://audio/sfx/misc/General_throw_miss.ogg")

const STARTER_PHRASES := [
	"Are you prepared to die on this hill?",
	"Must you make a mountain of everything?",
	"I think it's my turn to stomp you.",
]

var directory: Node3D
var mole_cog: Cog
var player: Player
var mole_hill: MoleHole


func _skip() -> void:
	super()
	override_shaking = true
	mole_cog.position = Vector3.ZERO
	player.global_position = battle_node.player_pos
	player.set_animation('neutral')
	set_camera_angle('StompCam')
	camera.look_at(battle_node.global_position)
	await BattleService.s_battle_started
	battle_node.focus_character(battle_node)

func play() -> Tween:
	# Get our dependencies
	directory = battle_node.get_parent()
	mole_cog = directory.mole_cog
	player = Util.get_player()
	mole_hill = directory.mole_hill
	
	movie = create_tween()
	
	# Player walks in
	movie.tween_callback(set_camera_angle.bind('IntroCam'))
	movie.tween_callback(player.set_animation.bind('walk'))
	movie.tween_callback(player.face_position.bind(get_char_position('WalkInPos')))
	movie.tween_property(player, 'global_position', get_char_position('WalkInPos'), 3.0)
	movie.set_trans(Tween.TRANS_QUAD)
	movie.parallel().tween_property(camera,'rotation_degrees:x', -90.0, 2.5).set_delay(0.5)
	movie.set_trans(Tween.TRANS_LINEAR)
	movie.tween_callback(player.set_animation.bind('neutral'))
	movie.tween_callback(player.face_position.bind(get_char_position('StompPos')))
	movie.tween_interval(1.0)
	
	# Mole Pops Up
	movie.tween_callback(set_camera_angle.bind('MoleFocus'))
	movie.tween_callback(player.toon.hide)
	movie.tween_property(mole_hill.mole_cog, 'position:y', MoleHole.UP_Y, 1.0)
	movie.tween_interval(2.0)
	movie.tween_callback(player.toon.show)
	
	# Player tries to stomp and gets launched
	movie.tween_callback(set_camera_angle.bind('StompCam'))
	movie.tween_callback(player.set_animation.bind('run'))
	movie.tween_property(player, 'global_position', get_char_position('StompPos'), 0.25)
	movie.tween_callback(player.set_animation.bind('slip-backward'))
	movie.tween_callback(shake_camera.bind(camera, 1.0, 0.1, true, false))
	movie.tween_callback(AudioManager.play_sound.bind(SFX_FLYBACK))
	movie.tween_callback(AudioManager.play_sound.bind(SFX_HIT))
	movie.tween_property(player, 'global_position', get_char_position('FlyAwayPos'), 1.0)
	movie.tween_interval(2.0)
	
	# Mole Cog emerges
	movie.tween_callback(AudioManager.play_sound.bind(SFX_JUMP))
	movie.tween_callback(set_camera_angle.bind('MoleFocus'))
	movie.tween_callback(mole_hill.mole_cog.hide)
	movie.tween_callback(mole_cog.show)
	movie.tween_callback(mole_cog.do_knockback)
	movie.tween_property(mole_cog,'position:y', 0.0, 1.0)
	movie.set_trans(Tween.TRANS_QUAD)
	movie.parallel().tween_property(camera,'rotation_degrees:x', 90.0, 2.0)
	movie.tween_interval(2.5)
	
	# Mole Cog Speaks
	movie.tween_callback(battle_node.focus_character.bind(mole_cog, -4.0))
	movie.tween_callback(mole_cog.speak.bind(STARTER_PHRASES.pick_random()))
	movie.tween_interval(4.0)
	movie.tween_callback(start_music)
	movie.tween_callback(mole_hill.hide)
	return movie

func set_camera_angle(angle : String) -> void:
	battle_node.battle_cam.global_transform = get_camera_angle(angle)

func get_char_position(pos : String) -> Vector3:
	return directory.get_char_position(pos)

func get_camera_angle(angle : String) -> Transform3D:
	return directory.get_camera_angle(angle)
