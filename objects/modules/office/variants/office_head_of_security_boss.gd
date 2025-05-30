extends Node3D

const BLOCKER_Z := -6.5
const BLOCKER_Z_END := 0.0
const WALL_POS := 0.791

const BOSS_MUSIC := "res://audio/music/encntr_hos/encntr_hos_asi.tres"

@onready var tv_static : MeshInstance3D = %Static
@onready var camera_angles : Node3D = %CameraAngles
@onready var char_positions : Node3D = %CharPositions
@onready var camera : Camera3D = %CutsceneCamera
@onready var painting : MeshInstance3D = %LB_LightPanel
@onready var skull_origin : Node3D = %SkullActor
@onready var puzzle : PuzzleBoss = %PuzzleBoss
@onready var elevator : Elevator = %office_elevator
@onready var door : CogDoor = %CogDoor
@onready var skull_dude : Node3D = %head_of_security
@onready var screen : MeshInstance3D = %Screen

var static_mat : FastNoiseLite
var boss_initialized := false
var walls_up := false
var watch_player := true:
	set(x):
		watch_player = x
		if not x:
			skull_origin.rotation_degrees = Vector3(0.0, -90.0, 0.0)
var transition_count := 0
var facility_music: AudioStream

var TRANSITION1_DIALOGUE : Array[String] = [
	"FIRST SECURITY LOCK DISENGAGED. FIREWALL INTEGRITY AT 66%.",
	"PROBABILITY THAT SUCCESS WAS DUE TO RANDOM CHANCE: 99.6%.",
	"INCREASING POWER OUTPUT TO 100%. DELETION OF TOON: IMMINENT.",
]
var TRANSITION2_DIALOGUE : Array[String] = [
	"WARNING. WARNING. SECOND SECURITY LOCK DISENGAGED.",
	"POWER INCREASED TO 137%. OVERHEATING COMPENSATION: ACTIVATED.",
	"RUN: FINAL_SECURITY_LOCK.GD"
]
var TRANSITION_DIAL : Array = [
	TRANSITION1_DIALOGUE, TRANSITION2_DIALOGUE
]

var phase_music_clips : Array = [
	6, 11
]


func _ready() -> void:
	static_mat = tv_static.get_surface_override_material(0).albedo_texture.noise

func _process(_delta : float) -> void:
	if static_mat:
		static_mat.seed = RandomService.randi_channel('true_random')
	
	if is_instance_valid(Util.get_player()) and watch_player:
		skull_origin.look_at(Util.get_player().global_position + Vector3(0.001, 0.001, 0.001))

func body_entered_room(body : Node3D) -> void:
	if body is Player and not boss_initialized:
		boss_initialized = true
		puzzle.phase = puzzle.BossPhase.INTRO

func game_won() -> void:
	elevator.open()
	door.unlock()
	%BossChestGroup.make_chests()
	Util.get_player().stats.charge_active_item(2)
	AudioManager.set_default_music(facility_music)
	AudioManager.stop_music()

func play_intro() -> Tween:
	# Remember the facility music
	facility_music = AudioManager.music_player.stream
	
	var player := Util.get_player()
	
	## MOVIE START
	var movie := create_tween()
	
	# Setup
	movie.tween_callback(func(): Util.stuck_lock = true)
	movie.tween_callback(func(): player.game_timer_tick = false)
	movie.tween_callback(camera.set_global_transform.bind(player.camera.camera.global_transform))
	movie.tween_callback(camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.STOPPED)
	movie.tween_callback(player.set_animation.bind("neutral"))
	movie.tween_callback(Input.set_mouse_mode.bind(Input.MOUSE_MODE_VISIBLE))
	
	# Pan camera to painting
	movie.tween_callback(
	func():
		var audio_player := AudioManager.play_sound(load("res://audio/sfx/sequences/hos/hos_intro.ogg"))
		%SkipButton.pressed.connect(audio_player.queue_free, CONNECT_ONE_SHOT)
	)
	movie.tween_callback(
	func():
			var fade_tween := AudioManager.fade_music(-80.0, 6.0)
			%SkipButton.pressed.connect(fade_tween.kill)
	)
	movie.tween_callback(do_camera_transition.bind('PaintingFocus', 3.0))
	movie.tween_interval(1.5)
	movie.tween_callback(door.add_lock)
	
	# Painting shakes
	var shake_amt := 30.0
	var shake_times := 8
	movie.set_trans(Tween.TRANS_BOUNCE)
	for i in shake_times:
		movie.tween_property(painting, 'rotation_degrees:y', shake_amt, 0.1)
		movie.tween_property(painting, 'rotation_degrees:y', -shake_amt, 0.1)
		shake_amt /= 2.0
	movie.tween_interval(1.0)
	
	# Painting turns around
	movie.set_trans(Tween.TRANS_QUAD)
	movie.set_ease(Tween.EASE_OUT)
	movie.tween_property(painting, 'rotation_degrees:y', 1980.0, 2.0)
	movie.tween_interval(1.25)
	movie.set_ease(Tween.EASE_IN_OUT)
	
	# Move to Skull View
	movie.tween_callback(do_camera_transition.bind('SkullFocus', 1.0))
	movie.tween_interval(0.5)
	
	# Turn on projector
	movie.tween_callback(func(): painting.get_surface_override_material(2).albedo_color = Color.WHITE)
	movie.tween_callback(func(): painting.get_surface_override_material(2).emission_enabled = true)
	
	# Bring in the Skull
	movie.tween_callback(skull_origin.set_scale.bind(Vector3(1.0, 0.01, 1.0)))
	movie.tween_callback(skull_origin.show)
	movie.tween_callback(skull_dude.set_animation.bind('intro'))
	movie.tween_property(skull_origin, 'scale:y', 1.0, 0.5)
	movie.tween_callback(skull_dude.speak.bind("SYSTEM BOOTING..."))
	movie.tween_interval(3.85)
	movie.parallel().tween_property(screen.get_surface_override_material(0), 'albedo_color', Color('ff2f2d'), 0.5).set_delay(3.5)
	movie.tween_callback(AudioManager.set_music.bind(load(BOSS_MUSIC)))
	movie.tween_callback(skull_dude.speak.bind("UNAUTHORIZED USER DETECTED."))
	movie.tween_interval(1.15)
	movie.tween_callback(skull_dude.set_animation.bind('idle-neutral'))
	movie.tween_interval(2.0)
	movie.tween_callback(skull_dude.speak.bind("IF: UNAUTHORIZED USER IS ALLOWED TO PROCEED; THEN: SECURITY WILL BE COMPROMISED."))
	movie.tween_interval(5.0)
	movie.tween_callback(skull_dude.speak.bind("PRINT: SAY 'GOODBYE WORLD', TOON."))
	movie.tween_interval(4.0)
	
	movie.set_trans(Tween.TRANS_LINEAR)
	
	## END MOVIE
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_callback(CameraTransition.from_current.bind(self, player.camera.camera, 4.0))
	movie.tween_callback(player.camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.WALK)
	movie.tween_callback(AudioManager.set_clip.bind(2))
	movie.tween_callback(func(): player.game_timer_tick = true)
	movie.tween_callback(%SkipButton.hide)
	movie.finished.connect(movie.kill)
	
	%SkipButton.show()
	%SkipButton.pressed.connect(skip_cutscene.bind(movie))
	
	return movie

func skip_cutscene(tween: Tween) -> void:
	tween.custom_step(10000.0)
	AudioManager.music_player.set_volume_db(0.0)
	%CogDoor.skip_tween()

func do_transition_cutscene() -> Tween:
	transition_count += 1
	AudioManager.set_clip(phase_music_clips[transition_count - 1])
	if transition_count == 2:
		AudioManager.set_clip_autoadvance(7, 8)
	var dialogue_set: Array[String] = TRANSITION_DIAL[mini(1, transition_count - 1)].duplicate()
	
	var transition_anim := 'angry'
	var idle_anim := 'idle-angry'
	var transition_time := 1.75
	var transition_angle := 'SkullFocus'
	
	if transition_count > 1:
		transition_anim = 'furious'
		idle_anim = 'idle-furious'
		transition_time = 2.0
		transition_angle = 'SkullFurious'
	
	var player := Util.get_player()
	
	## MOVIE START
	var movie := create_tween()
	
	# Setup
	movie.tween_callback(func(): player.game_timer_tick = false)
	movie.tween_callback(camera.set_global_transform.bind(player.camera.camera.global_transform))
	movie.tween_callback(camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.STOPPED)
	
	# Move to skull focus
	movie.tween_callback(do_camera_transition.bind(transition_angle, 2.0))
	
	# Make player run back to puzzle start
	movie.tween_callback(
		func():
			var tween := player.move_to(get_char_position('PuzzleStart'))
			tween.finished.connect(player.face_position.bind(skull_origin.global_position))
			)
	
	if not walls_up:
		walls_up = true
		movie.parallel().tween_callback(%Walls.show)
		movie.parallel().set_trans(Tween.TRANS_QUAD)
		movie.parallel().tween_property(%Walls, 'position:y', WALL_POS, 3.0)
		movie.parallel().set_trans(Tween.TRANS_LINEAR)

	# Wait a few seconds
	movie.tween_interval(2.0)
	
	# He's angry
	movie.tween_callback(skull_dude.set_animation.bind(transition_anim))
	movie.tween_callback(skull_dude.speak.bind(dialogue_set.pop_front()))
	movie.tween_property(skull_dude, 'shake_intensity', skull_dude.shake_intensity + 0.5, transition_time)
	movie.tween_callback(func(): skull_dude.GLITCH_TIME += 0.1)
	movie.tween_callback(skull_dude.set_animation.bind(idle_anim))
	movie.tween_interval(2.25)
	
	for dial in dialogue_set:
		append_dialogue(movie, dial)
	
	# Transition back to player cam
	movie.tween_callback(CameraTransition.from_current.bind(player, player.camera.camera, 4.0))
	movie.tween_interval(5.0)
	
	# Cleanup
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_callback(CameraTransition.from_current.bind(self, player.camera.camera, 4.0))
	movie.tween_callback(player.camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.WALK)
	movie.tween_callback(func(): player.game_timer_tick = true)
	movie.finished.connect(movie.kill)
	
	return movie

func do_end_cutscene() -> Tween:
	var player := Util.get_player()
	
	var death_phrases: Array[String] = [
		"SYSTEM COMPROMISED. SYSTEM COMPROMISED.",
		"01100010 01100001 01110010 01110000",
		"RETURN: VOID."
	]
	
	# Reset skull rotation
	watch_player = false
	
	## MOVIE START
	var movie := create_tween()
	
	# Setup
	movie.tween_callback(func(): Util.stuck_lock = false)
	movie.tween_callback(func(): player.game_timer_tick = false)
	movie.tween_callback(camera.set_global_transform.bind(get_camera_angle('SkullFocus').global_transform))
	movie.tween_callback(camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.STOPPED)
	movie.tween_callback(player.set_animation.bind('neutral'))
	
	# Do animation
	movie.tween_callback(skull_dude.speak.bind("WARNING. WARNING. FIREWALL HAS BEEN DISENGAGED."))
	movie.tween_callback(skull_dude.set_animation.bind('death'))
	movie.tween_callback(AudioManager.set_clip.bind(12))
	movie.tween_interval(3.0)
	movie.tween_callback(skull_dude.speak.bind("IMPOSSIBLE OUTCOME REACHED."))
	movie.tween_interval(3.0)
	movie.tween_callback(skull_dude.speak.bind(RandomService.array_pick_random('true_random', death_phrases)))
	
	# Move them walls down
	movie.tween_property(%Walls, 'position:y', -4.197, 2.0)
	movie.tween_callback(skull_dude.do_explosion)
	
	# Flip painting back around
	movie.set_trans(Tween.TRANS_QUAD)
	movie.set_ease(Tween.EASE_OUT)
	movie.tween_property(painting, 'rotation_degrees:y', 0.0, 2.0)
	
	# Cleanup
	movie.tween_callback(CameraTransition.from_current.bind(self, player.camera.camera, 4.0))
	movie.tween_interval(4.0)
	movie.tween_callback(player.camera.make_current)
	movie.tween_callback(func(): player.state = Player.PlayerState.WALK)
	movie.tween_callback(func(): player.game_timer_tick = true)
	movie.finished.connect(movie.kill)
	
	return movie

#region MOVIE FUNCS
## Returns the camera at the specified angle
func get_camera_angle(angle : String) -> Camera3D:
	return camera_angles.find_child(angle)

## Makes the specified camera the current camera
func set_camera_angle(angle : String) -> void:
	camera.global_transform = get_camera_angle(angle).global_transform

func get_char_position(pos : String) -> Vector3:
	return char_positions.get_node(pos).global_position

## Does a camera transition tween
func do_camera_transition(angle : String, time : float) -> void:
	CameraTransition.from_current(self, get_camera_angle(angle), time)

func append_dialogue(tween : Tween, dialogue : String, time := 4.0) -> void:
	tween.tween_callback(skull_dude.speak.bind(dialogue))
	tween.tween_interval(time)

#endregion

#region Dynamic Music

var skullfinder_clips = {
	2: 3,
	5: 4,
	8: 5
}

func skullfinder_row_reached(row_num: int) -> void:
	print("Row Discovered: " + str(row_num))
	if row_num in skullfinder_clips.keys():
		AudioManager.set_clip(skullfinder_clips[row_num])

#endregion
