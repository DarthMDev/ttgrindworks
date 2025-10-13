extends Area3D

signal s_pipe_connected(pipe: Area3D)

@export var connected_pipe: Area3D:
	set(x):
		connected_pipe = x
		if 'connected_pipe' in x:
			if not x.connected_pipe == self:
				x.connected_pipe = self
				s_pipe_connected.emit(x)

func on_body_entered(body) -> void:
	if body is Player:
		on_player_entered(body)

func on_player_entered(player: Player) -> void:
	if player.state == Player.PlayerState.WALK:
		if connected_pipe:
			var volume := await run_in(player)
			connected_pipe.run_out(player, volume)
		else:
			run_in_fakeout(player)

func run_in_fakeout(player: Player) -> void:
	player.global_position.y = %RunInPos.global_position.y
	%Camera.make_current()
	player.move_to(%RunInPos.global_position)
	var music_vol := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var fade_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_method(set_music_vol, music_vol, -80.0, 2.0)
	await fade_tween.finished
	
	AudioManager.play_sound(load('res://audio/sfx/objects/liquidator/liquidator_roar.ogg'))
	Util.shake_camera(%Camera, 5.0, 0.25, true)
	await Task.delay(5.5)
	player.toon.set_emotion(Toon.Emotion.SURPRISE)
	
	var music_tween2 := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	music_tween2.tween_method(set_music_vol, -80.0, music_vol, 2.0)
	await player.move_to(%RunOutPos.global_position).finished
	player.camera.make_current()
	player.state = Player.PlayerState.WALK
	Task.delay(3.0).connect(player.toon.set_emotion.bind(Toon.Emotion.NEUTRAL))

func run_in(player: Player) -> float:
	player.global_position.y = %RunInPos.global_position.y
	%Camera.make_current()
	await player.move_to(%RunInPos.global_position).finished
	Util.circle_out(2.0)
	var master_vol := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	var fade_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_method(set_master_vol, master_vol, -80.0, 2.0)
	await fade_tween.finished
	return master_vol

func set_master_vol(vol: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), vol)

func set_music_vol(vol: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), vol)

func run_out(player: Player, volume: float) -> void:
	player.global_position = %RunInPos.global_position
	%Camera.make_current()
	Util.circle_in(2.0)
	var fade_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.tween_method(set_master_vol, -80.0, volume, 2.0)
	await fade_tween.finished
	await player.move_to(%RunOutPos.global_position).finished
	player.camera.make_current()
	player.state = Player.PlayerState.WALK
