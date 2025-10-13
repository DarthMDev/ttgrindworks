extends "res://objects/modules/molten/variants/chase_boss/stage_pieces/molten_hall_piece.gd"


var player_entered := false
var cutscene_played := false
var cutscene: Tween

signal s_player_entered_final_room
signal s_door_closed
signal s_game_won
signal s_cutscene_started


func on_body_entered_room(body: Node3D) -> void:
	if body is Player:
		player_entered_room()

func player_entered_room() -> void:
	if not player_entered:
		player_entered = true
		%DoorCloser.play('close')
		s_player_entered_final_room.emit()

func body_entered_win(body) -> void:
	if body is Player:
		player_win()

func door_anim_finished(anim: StringName) -> void:
	if anim == &'close':
		s_door_closed.emit()

func player_win() -> void:
	if not cutscene_played:
		play_win_cutscene()
		cutscene_played = true
		%LavaSmall.show()

func boss_ended() -> void:
	%BossChestGroup.make_chests()

## Win Cutscene
func play_win_cutscene() -> void:
	for platform in %Platforms.get_children():
		if platform is CrumblingPlatform:
			platform.activate_crumble()
	s_cutscene_started.emit()
	var player := Util.get_player()
	player.state = Player.PlayerState.STOPPED
	player.game_timer_tick = false
	player.toon.set_blink_paused(true)
	player.global_position = %PlayerStartPos.global_position
	player.face_position(%Liquidator.global_position)
	var hes_right_behind_me_rotation := player.toon.quaternion
	
	cutscene = create_tween()
	cutscene.tween_callback(
		func():
			AudioManager.play_snippet(load("res://audio/sfx/objects/liquidator/ending.ogg"), 0.6)
	)
	# Player falls onto end platform
	cutscene.tween_callback(AudioManager.set_music.bind(load('res://audio/music/molten_mint/liquidator_end.ogg')))
	cutscene.tween_callback(%StartCam.make_current)
	cutscene.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.SURPRISE))
	cutscene.tween_callback(player.face_position.bind(%PlayerFallTo.global_position))
	cutscene.tween_callback(player.set_animation.bind('zhang'))
	cutscene.tween_property(player, 'global_position', %PlayerFallTo.global_position, 0.4)
	cutscene.parallel().tween_property(%StartCam, 'rotation_degrees:x', 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_delay(0.2)
	cutscene.parallel().tween_callback(player.set_animation.bind('slip-forward')).set_delay(0.1)
	
	# Player Landing
	cutscene.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.ANGRY))
	cutscene.tween_callback(player.toon.set_mouth.bind(Toon.Emotion.ANGRY))
	cutscene.tween_callback(player.toon.close_eyes)
	cutscene.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/toon/target_impact_grunt1.ogg")))
	cutscene.tween_property(player, 'global_position', %PlayerSlideTo.global_position, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cutscene.tween_callback(player.toon.anim_pause)
	cutscene.tween_interval(0.25)
	cutscene.tween_callback(player.toon.anim_set_speed.bind(1.0))
	cutscene.tween_callback(player.toon.anim_unpause)
	cutscene.tween_callback(player.toon.open_eyes)
	cutscene.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.NEUTRAL))
	
	# HERE IT COMES
	cutscene.tween_callback(%Liquidator.set_animation.bind('Walk'))
	cutscene.tween_interval(0.1)
	cutscene.tween_callback(%Liquidator.show)
	cutscene.tween_property(%Liquidator, 'position:y', -3.592, 5.0).set_trans(Tween.TRANS_QUAD)
	cutscene.parallel().tween_callback(%SFXEmerge.play).set_delay(1.5)
	cutscene.parallel().tween_property(%StartCam, 'global_transform', %HesRightBehindMeIsntHe.global_transform, 5.0).set_trans(Tween.TRANS_QUAD)
	cutscene.parallel().tween_callback(func(): %LavaSplash.emitting = true).set_delay(2.25)
	var turn_delay := 1.25
	var turn_time := 2.0
	cutscene.parallel().tween_callback(player.toon.anim_set_speed.bind(1.0)).set_delay(turn_delay)
	cutscene.parallel().tween_callback(player.toon.set_mouth.bind(Toon.Emotion.NEUTRAL)).set_delay(turn_delay)
	cutscene.parallel().tween_callback(player.set_animation.bind('walk')).set_delay(turn_delay)
	cutscene.parallel().tween_property(player.toon, 'quaternion', hes_right_behind_me_rotation, turn_time).set_delay(turn_delay)
	cutscene.parallel().tween_callback(player.set_animation.bind('neutral')).set_delay(turn_delay + turn_time + 0.05)
	cutscene.tween_callback(func(): move_liquidator = true)
	
	# Player back onto button
	cutscene.tween_callback(player.set_animation.bind('walk'))
	cutscene.tween_callback(player.toon.anim_set_speed.bind(-1.0))
	cutscene.tween_property(player, 'global_position', %PlayerWalkBackTo.global_position, 2.2)
	cutscene.parallel().tween_property(%StartCam, 'global_transform', %ButtonCam.global_transform, 1.5).set_trans(Tween.TRANS_QUAD)
	cutscene.tween_callback(player.toon.anim_pause)
	cutscene.tween_callback(player.toon.anim_set_speed.bind(1.0))
	cutscene.tween_callback(player.set_animation.bind('conked'))
	cutscene.tween_callback(%CogButton.press)
	cutscene.tween_callback(func(): move_liquidator = false)
	#cutscene.tween_callback(AudioManager.play_sound.bind(load('res://audio/sfx/objects/liquidator/liquidator_spit.ogg')))
	cutscene.tween_callback(%Liquidator.set_animation.bind('Grunt'))
	cutscene.tween_interval(1.75)
	
	# Liquidator DIE
	cutscene.tween_callback(player.set_animation.bind('neutral'))
	cutscene.tween_callback(%LiquidatorDeathCam.make_current)
	cutscene.tween_callback(%Liquidator.set_animation.bind('Death'))
	cutscene.tween_callback(%FinalPlatform.queue_free)
	cutscene.tween_callback(func(): %LavaSplashConstant.emitting = true)
	cutscene.tween_interval(8.0)
	cutscene.parallel().tween_property(%Liquidator, 'global_position', %LiquidatorDeathPos.global_position, 4.0).set_delay(4.0)
	cutscene.parallel().tween_property(%Liquidator, 'scale', Vector3.ONE * 0.05, 6.0).set_delay(2.0)
	cutscene.parallel().tween_property(%LavaSmall, 'position:y', -6.0, 2.0).set_trans(Tween.TRANS_QUAD).set_delay(4.0)
	cutscene.parallel().tween_property(%LiquidatorDeathCam, 'rotation_degrees:x', -25.0, 4.0).set_delay(4.0).set_trans(Tween.TRANS_QUAD)
	cutscene.tween_callback(func(): %LavaSplashConstant.emitting = false)
	cutscene.tween_callback(%Liquidator.hide)
	
	cutscene.tween_callback(s_game_won.emit)
	cutscene.tween_callback(player.toon.set_blink_paused.bind(false))
	cutscene.tween_callback(func(): player.game_timer_tick = true)
	cutscene.finished.connect(cutscene.kill)

const LIQUIDATOR_MOVE_SPEED := 2.0
var move_liquidator := false
func _process(delta: float) -> void:
	if move_liquidator:
		%Liquidator.position.x += LIQUIDATOR_MOVE_SPEED * delta

func _ready() -> void:
	# Try and connect the shop pipe
	var current_scene: Node = SceneLoader.current_scene
	if current_scene is GameFloor:
		var rooms: Array[Node] = current_scene.room_node.get_children()
		for room in rooms:
			if room.has_node('BigPipeTransport'):
				room.get_node('BigPipeTransport').connected_pipe = %BigPipe2
	super()
