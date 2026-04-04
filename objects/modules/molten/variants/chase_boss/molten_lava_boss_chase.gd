extends Node3D

const FIREBALL_POS := Vector3(0.0, 3.0, -10.0)
const FIREBALL_XPOS := [6.0, -6.0]
var ROOM_COUNT: int:
	get:
		if Util.on_easy_floor(): return 8
		return 10
const CAMERA_VELOCITY := 4.0
const EXIT_ROOM := "res://objects/modules/molten/variants/chase_boss/stage_pieces/molten_hall_final.tscn"
const BOSS_FOLLOW_DELAY := 8.0
const FOV_RANGE := Vector2(50.0, 54.0)

enum BossState {
	INACTIVE,
	TUTORIAL,
	INTRO,
	ACTIVE,
	WIN
}
var state := BossState.INACTIVE
var player: Player
var CHASE_SPEED_RANGE := Vector2(0.7, 1.4)
var fireballs_enabled := false
var lava_damage := -4

@export var straight_pieces: Array[PackedScene] = []
@export var left_pieces: Array[PackedScene] = []
@export var right_pieces: Array[PackedScene] = []
@export var dev_run_checkpoint_test := false

@onready var rooms: Node3D = %Rooms
@onready var camera: Camera3D = %ChaseCam
@onready var follower: PathFollow3D = %CameraFollow
@onready var boss_follower: PathFollow3D = %BossFollow
@onready var respawn_point: Node3D = %InitialRespawn
@onready var liquidator: Node3D = %Liquidator
@onready var player_marker: Control3D = %PlayerMarker


var camera_tween: Tween
var boss_tween: Tween
var rotation_tween: Tween
var room_index := 0
var boss_room_index := 0
var dir := -1
var chase_speed: float = 1.0
var cutscene: Tween
var lava_level := 0.0:
	get: return %BeginningLavaFloor.global_position.y
var checkpoint_tester
var final_respawn: Node3D
var exit_room: Node3D


func _ready() -> void:
	%Liquidator.hide()
	
	# Set up the first room's respawn points
	for area3d: Area3D in %RespawnPoints.get_children():
		area3d.area_entered.connect(
			func(area: Area3D):
				if area.name == 'ChaseCamCollide':
					on_respawn_point_reached(area3d.get_node('Pos'))
		)

func begin_chase() -> void:
	player.game_timer_tick = true
	player_marker.target = player.toon.speech_bubble_node
	
	state = BossState.ACTIVE
	%LavaBig.show()
	%LavaSmall.hide()
	%BeginningLavaFloor.set_deferred('monitoring', false)
	do_boss_follow(boss_room_index)
	do_camera_follow(room_index)
	camera_tween.custom_step(BOSS_FOLLOW_DELAY)
	camera.make_current()
	%Liquidator.set_animation(&'Walk')
	liquidator.neutral_anim = &'Walk'
	%SpeedupTimer.start()
	
	if dev_run_checkpoint_test and OS.has_feature('debug'):
		checkpoint_tester = load('res://models/props/gags/pie/pie.glb').instantiate()
		add_child(checkpoint_tester)
	
	do_liquidator_spit_cycle()
	
	player.s_dying.connect(player_died)
	
	await get_tree().process_frame
	player.global_position = %PlayerBossStartPoint.global_position
	player.state = Player.PlayerState.CHASE

func do_liquidator_spit_cycle() -> void:
	fireballs_enabled = true
	while fireballs_enabled:
		await Task.delay(2.0)
		if not roundi(boss_follower.rotation_degrees.y) % 90 == 0:
			continue
		var fireball: Area3D = await liquidator.spit()
		if not fireball: return
		var fireball_pos := get_random_fireball_pos()
		fireball.global_rotation.y = liquidator.global_rotation.y
		var tween := create_tween().set_parallel()
		tween.tween_property(fireball, 'position', fireball_pos, 0.25)
		await tween.finished
		tween.kill()
		fireball.velocity = fireball.global_transform.basis * Vector3(0,0, -15.0)


func get_random_fireball_pos() -> Vector3:
	var fireball_pos := FIREBALL_POS
	fireball_pos.x = FIREBALL_XPOS.pick_random()
	return boss_follower.to_global(fireball_pos)

func do_camera_follow(idx: int) -> void:
	if camera_tween and camera_tween.is_running():
		camera_tween.kill()
	var room: Node3D = rooms.get_child(idx)
	var path: Path3D = room.get_node('CameraPath')
	var length := path.curve.get_baked_length()
	var room_time := length / CAMERA_VELOCITY
	var transition_length := follower.global_position.distance_to(path.global_position)
	var transition_time := transition_length / CAMERA_VELOCITY
	
	var prev_transform := follower.global_transform
	follower.reparent(path)
	follower.progress = 0.0
	follower.reparent(self)
	var goal_rotation = follower.quaternion
	follower.global_transform = prev_transform
	
	camera_tween = create_tween()
	camera_tween.tween_property(follower, 'global_position', path.global_position, transition_time)
	camera_tween.parallel().tween_property(follower, 'quaternion', goal_rotation, transition_time)
	camera_tween.tween_callback(follower.set_progress.bind(0.0))
	camera_tween.tween_callback(follower.reparent.bind(path))
	camera_tween.tween_callback(follower.reset_physics_interpolation)
	camera_tween.tween_property(follower, 'progress', length, room_time)
	camera_tween.finished.connect(room_finished)

func do_boss_follow(idx: int) -> void:
	
	if boss_tween and boss_tween.is_running():
		boss_tween.kill()
	var room: Node3D = rooms.get_child(idx)
	var path: Path3D = room.get_node('BossPath')
	var length := path.curve.get_baked_length()
	var room_time := length / CAMERA_VELOCITY
	var transition_length := boss_follower.global_position.distance_to(path.global_position)
	var transition_time := transition_length / CAMERA_VELOCITY
	
	var prev_transform := boss_follower.global_transform
	boss_follower.reparent(path)
	boss_follower.progress = 0.0
	boss_follower.reparent(self)
	var goal_rotation = boss_follower.quaternion
	boss_follower.global_transform = prev_transform

	boss_tween = create_tween()
	boss_tween.tween_property(boss_follower, 'global_position', path.global_position, transition_time)
	boss_tween.parallel().tween_property(boss_follower, 'quaternion', goal_rotation, transition_time)
	boss_tween.tween_callback(boss_follower.set_progress.bind(0.0))
	boss_tween.tween_callback(boss_follower.reparent.bind(path))
	boss_tween.tween_callback(boss_follower.reset_physics_interpolation)
	boss_tween.tween_property(boss_follower, 'progress', length, room_time)
	boss_tween.finished.connect(boss_room_finished)

func room_finished() -> void:
	camera_tween.kill()
	room_index += 1
	if room_index < rooms.get_child_count():
		do_camera_follow(room_index)
	if room_index == rooms.get_child_count() -1:
		fireballs_enabled = false

func boss_room_finished() -> void:
	boss_tween.kill()
	boss_room_index += 1
	if boss_room_index == rooms.get_child_count() - 1: fireballs_enabled = false
	if boss_room_index < rooms.get_child_count():
		do_boss_follow(boss_room_index)

func on_end_cutscene_start() -> void:
	%LavaBig.hide()
	%LavaSmall.show()

func end_boss() -> void:
	unload_chase()
	%BeginningLavaFloor.set_deferred('monitoring', true)
	state = BossState.WIN
	Globals.s_liquidator_boss_defeated.emit()
	respawn_point = rooms.get_child(-1).get_node('PlayerPos')
	exit_room.boss_ended()
	%InvisWall.disabled = false
	await CameraTransition.from_current(self, player.camera.camera, 4.0).s_done
	player.state = Player.PlayerState.WALK
	player.stats.charge_active_item(2)
	%RecoveryBellows.position = Vector3(-2.877, 0.893, 0.899)
	AudioManager.stop_music(true)
	AudioManager.set_default_music(load('res://audio/music/molten_mint/molten_mint.ogg'))
	ScoreTally.modify_score(ScoreTally.ChannelBosses, ScoreTally.BOSS_BONUS)

func unload_chase() -> void:
	for room in rooms.get_children():
		if not room == exit_room and rooms.get_children().find(room) > 1:
			room.queue_free()

func body_entered(body: Node3D) -> void:
	if body is Player:
		on_player_entered(body)

func on_player_entered(plyr: Player) -> void:
	player = plyr
	if not state == BossState.TUTORIAL and not state == BossState.INACTIVE: return
	state = BossState.INTRO
	do_intro_cutscene()

func on_intro_end() -> void:
	%SkipButton.hide()
	generate_chase()
	begin_chase()
	AudioManager.set_music(load('res://audio/music/molten_mint/liquidator_boss.ogg'))

func generate_chase() -> void:
	for i in ROOM_COUNT - 1:
		var change_dir := RNG.channel(RNG.ChannelMoltenChaseGeneration).randi() % 4 == 0
		var room_array: Array[PackedScene]
		if change_dir:
			dir = -dir
			match dir:
				-1: 
					room_array = right_pieces
				1: 
					room_array = left_pieces
		else:
			room_array = straight_pieces
		append_room(RNG.channel(RNG.ChannelMoltenChaseGeneration).pick_random(room_array).instantiate())
	
	append_exit()
	
	for child in rooms.get_children():
		child.s_respawn_point_reached.connect(on_respawn_point_reached)

func append_exit() -> void:
	exit_room = load(EXIT_ROOM).instantiate()
	append_room(exit_room)
	exit_room.s_player_entered_final_room.connect(on_final_room_entered)
	exit_room.s_game_won.connect(end_boss)
	exit_room.s_cutscene_started.connect(on_end_cutscene_start)

func append_room(room: Node3D) -> void:
	
	var prev_room: Node3D = rooms
	var prev_exit: Node3D = rooms
	if rooms.get_child_count() > 0:
		prev_exit = rooms.get_child(rooms.get_child_count() - 1).get_node('EXIT')
		prev_room = rooms.get_child(rooms.get_child_count() - 1)
	rooms.add_child(room)
	var new_entrance = room.get_node('ENTRANCE')
	
	# Rotate the new room
	var rot = prev_room.global_rotation.y
	room.global_rotation.y = rot
	room.rotation.y += prev_exit.rotation.y + new_entrance.rotation.y

	# Get reference info
	var entrance_pos = new_entrance.position
	var entrance_global_pos = new_entrance.global_position
	
	# Place new entrance on previous exit
	new_entrance.global_position = prev_exit.global_position
	
	# Get difference between entrance's old and new positions
	var pos_diff = new_entrance.global_position - entrance_global_pos
	
	# Apply the difference to the new module
	room.global_position += pos_diff
	
	# Reset entrance node pos
	new_entrance.position = entrance_pos

func player_died() -> void:
	if boss_tween and boss_tween.is_running():
		boss_tween.kill()
		fireballs_enabled = false
		liquidator.roar()
		liquidator.neutral_anim = &'Idle'
	if camera_tween and camera_tween.is_running():
		camera_tween.kill()
	state = BossState.INACTIVE

func _process(delta: float) -> void:
	if state == BossState.TUTORIAL:
		%TutorialCamFollow.progress_ratio = minf(%TutorialCamFollow.progress_ratio + (delta * 0.1), 1.0)
	
	if not state == BossState.ACTIVE:
		return
	
	# Chase speed scaling
	var boss_distance := absf(boss_follower.global_position.distance_to(player.global_position))
	var camera_distance := absf(camera.global_position.distance_to(player.global_position))
	
	# We want the player roughly in the middle of these two
	# So let's see the ratio of the two distances
	var distance_ratio := boss_distance / camera_distance
	
	var chase_speed_goal := clampf(distance_ratio, CHASE_SPEED_RANGE.x, CHASE_SPEED_RANGE.y)
	chase_speed = lerpf(chase_speed, chase_speed_goal, 0.25)
	
	var fov_range := FOV_RANGE.y - FOV_RANGE.x
	var fov_goal := clampf(FOV_RANGE.x + (fov_range * (distance_ratio - 1.0)), FOV_RANGE.x, FOV_RANGE.y)
	%ChaseCam.fov = lerpf(%ChaseCam.fov, fov_goal, 0.1)
	
	if boss_tween and boss_tween.is_running():
		boss_tween.set_speed_scale(chase_speed)
	if camera_tween and camera_tween.is_running():
		camera_tween.set_speed_scale(chase_speed)

func _physics_process(_delta: float) -> void:
	if not state == BossState.ACTIVE and not state == BossState.TUTORIAL: return
	
	if player.global_position.y < lava_level:
		respawn_player()

func do_intro_cutscene() -> void:
	player.game_timer_tick = false
	if cutscene: return
	AudioManager.set_music(load('res://audio/music/molten_mint/liquidator_intro.ogg'))
	cutscene = create_tween()
	
	# Player walk to pos
	var transition_time := 3.0
	var wait_time := 2.0
	cutscene.tween_callback(func(): player.state = Player.PlayerState.STOPPED)
	cutscene.tween_callback(Input.set_mouse_mode.bind(Input.MOUSE_MODE_VISIBLE))
	cutscene.tween_callback(player.set_animation.bind('neutral'))
	cutscene.tween_callback(CameraTransition.from_current.bind(self, %IntroCam2, transition_time))
	cutscene.tween_callback(player.set_animation.bind('walk'))
	cutscene.tween_callback(player.face_position.bind(%PlayerWalkTo.global_position))
	cutscene.tween_property(player, 'global_position:x', %PlayerWalkTo.global_position.x, transition_time)
	cutscene.parallel().tween_property(player, 'global_position:z', %PlayerWalkTo.global_position.z, transition_time)
	cutscene.parallel().tween_property(player, 'global_position:y', %PlayerWalkTo.global_position.y, 0.1)
	cutscene.tween_callback(player.face_position.bind(%PlayerFace.global_position))
	cutscene.tween_callback(Util.shake_camera.bind(%IntroCam2, 2.0, 0.12, true))
	cutscene.tween_callback(%LavaBubbles.set_emitting.bind(true))
	cutscene.tween_callback(player.set_animation.bind('confused'))
	cutscene.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/toon/avatar_emotion_confused.ogg")))
	cutscene.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/objects/liquidator/intro_preroar.ogg")))
	cutscene.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.SURPRISE))
	cutscene.tween_callback(player.toon.set_mouth.bind(Toon.Emotion.ANGRY))
	cutscene.tween_interval(wait_time)
	#cutscene.parallel().tween_callback(%SFXQuake.play)
	#cutscene.parallel().tween_method(%SFXQuake.set_volume_db, -100.0, 0.0, 0.25)
	
	
	# Transition to lava cam
	transition_time = 3.0
	cutscene.tween_callback(CameraTransition.from_current.bind(self, %LavaFocus, transition_time))
	cutscene.tween_callback(player.set_animation.bind('walk'))
	cutscene.tween_property(player.toon, 'rotation_degrees:y', -180.0, transition_time).as_relative()
	#cutscene.parallel().tween_callback(%SFXEmerge.play).set_delay(wait_time)
	cutscene.tween_callback(player.set_animation.bind('neutral'))
	
	transition_time = 3.0
	var anim_time := 3.3
	var rise_time := 0.5
	cutscene.tween_callback(%Liquidator.set_animation.bind('Intro'))
	cutscene.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/objects/liquidator/intro_riserimpact.ogg")))
	cutscene.tween_callback(%Liquidator.animator.seek.bind(0.65))
	# Give some wiggle room for the anim to refresh
	cutscene.tween_interval(0.01)
	cutscene.tween_callback(%Liquidator.show)
	#cutscene.tween_callback(%SFXQuake.stop)
	cutscene.tween_callback(CameraTransition.from_current.bind(self, %BossFocus, transition_time))
	cutscene.tween_callback(func(): %Liquidator.collider.set_deferred('monitoring', true))
	cutscene.tween_callback(func(): %LavaSplash.emitting = true)
	cutscene.tween_property(%Liquidator, 'position:y', 0.0, rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	cutscene.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	cutscene.tween_interval(anim_time - rise_time)
	#cutscene.parallel().tween_callback(AudioManager.play_sound.bind(load())).set_delay((anim_time - rise_time) - 0.5)
	
	# Liquidator MAD!!!
	wait_time = 2.0
	cutscene.tween_callback(%TextSprawl.do_sprawl)
	cutscene.tween_callback(liquidator.roar)
	cutscene.tween_callback(%SpeedLines.show)
	cutscene.tween_property(%BossFocus, 'fov', 75.0, 2.0).set_trans(Tween.TRANS_QUAD)
	cutscene.parallel().tween_method(set_speed_lines_level, 1.0, 0.5, 2.0).set_trans(Tween.TRANS_QUAD)
	cutscene.tween_interval(1.5)
	cutscene.tween_property(%BossFocus, 'fov', 52.0, 0.5).set_trans(Tween.TRANS_QUAD)
	cutscene.parallel().tween_method(set_speed_lines_level, 0.5, 1.0, 0.5).set_trans(Tween.TRANS_QUAD)
	cutscene.tween_callback(%SpeedLines.hide)
	cutscene.tween_interval(1.0)
	cutscene.tween_callback(%Liquidator.set_animation.bind('Idle'))
	cutscene.tween_interval(wait_time)
	
	cutscene.finished.connect(cutscene.kill)
	cutscene.finished.connect(on_intro_end)
	
	# Skipping :)
	%SkipButton.show()

func skip_cutscene() -> void:
	cutscene.custom_step(10000.0)
	if %TextSprawl.sprawl_tween and %TextSprawl.sprawl_tween.is_running():
		%TextSprawl.sprawl_tween.custom_step(1000.0)
	liquidator.sfx_player.stop()

func set_speed_lines_level(level: float) -> void:
	%SpeedLines.get_material().set_shader_parameter('mask_edge', level)

func on_respawn_point_reached(node: Node3D) -> void:
	respawn_point = node
	if checkpoint_tester:
		checkpoint_tester.global_position = node.global_position

func respawn_player() -> void:
	player.last_damage_source = %BeginningLavaFloor.damage_name
	if state == BossState.TUTORIAL:
		player.global_position = %TutorialRespawn.global_position
	else: 
		player.global_position = respawn_point.global_position
		show_player_marker()
	player.quick_heal(Util.get_hazard_damage(-4))
	await player.teleport_in()
	if player.stats.hp <= 0:
		player.set_animation('lose')
	if state == BossState.ACTIVE or state == BossState.TUTORIAL:
		player.state = Player.PlayerState.CHASE
	else:
		player.state = Player.PlayerState.WALK

var marker_tween: Tween
func show_player_marker() -> void:
	player_marker.force_hide = false
	player_marker.modulate.a = 1.0
	if marker_tween and marker_tween.is_running():
		marker_tween.kill()
	marker_tween = create_tween()
	marker_tween.tween_interval(4.0)
	marker_tween.tween_property(player_marker, 'modulate:a', 0.0, 2.0)

func on_player_collided_with_boss(_plyr: Player) -> void:
	if not state == BossState.INACTIVE:
		respawn_player()
		player.last_damage_source = "The Liquidator"

func on_final_room_entered() -> void:
	liquidator.roar()

func on_speedup() -> void:
	CHASE_SPEED_RANGE += Vector2(0.01, 0.01)

#region TUTORIAL THINGY
func on_body_entered_tutorial(body: Node3D) -> void:
	if body is Player and state == BossState.INACTIVE:
		player = body
		start_tutorial()

func start_tutorial() -> void:
	play_tutorial_cutscene()

func play_tutorial_cutscene() -> void:
	cutscene = create_tween()
	player.state = Player.PlayerState.STOPPED
	player.game_timer_tick = false
	
	cutscene.tween_callback(%TutorialCam1.make_current)
	cutscene.tween_callback(Input.set_mouse_mode.bind(Input.MOUSE_MODE_VISIBLE))
	cutscene.tween_callback(AudioManager.fade_music.bind(-80.0, 3.0))
	
	# Make player walk to end of bridge
	cutscene.tween_callback(player.set_global_position.bind(%TutorialStart.global_position))
	cutscene.tween_callback(player.set_animation.bind('run'))
	cutscene.tween_callback(player.face_position.bind(%TutorialWalkTo.global_position))
	cutscene.tween_property(player, 'global_position', %TutorialWalkTo.global_position, 1.25)
	cutscene.tween_callback(player.set_animation.bind('jump'))
	cutscene.tween_interval(0.5)
	cutscene.tween_callback(CameraTransition.from_current.bind(self, %TutorialCam2, 1.0))
	cutscene.tween_property(player, 'global_position', %TutorialJumpTo.global_position, 0.5)
	cutscene.tween_callback(player.toon.anim_seek.bind(0.6))
	cutscene.tween_property(player, 'global_position', %TutorialFallTo.global_position, 0.5)
	cutscene.parallel().tween_callback(player.face_position.bind(%PlayerStart.global_position)).set_delay(0.2)
	cutscene.tween_interval(1.0)
	
	cutscene.finished.connect(on_tutorial_cutscene_finished)

func on_tutorial_cutscene_finished() -> void:
	AudioManager.set_music_volume(0.0)
	state = BossState.TUTORIAL
	player.game_timer_tick = true
	cutscene.kill()
	cutscene = null
	player.state = Player.PlayerState.CHASE
	
	var fadein := create_tween()
	fadein.tween_property(%DirectionPrompt, 'modulate:a', 1.0, 0.5)
	fadein.finished.connect(fadein.kill)
	
	await Task.delay(3.0)
	var fadeout := create_tween()
	fadeout.tween_property(%DirectionPrompt, 'modulate:a', 0.0, 2.0)
	fadeout.finished.connect(fadeout.kill)

#endregion
