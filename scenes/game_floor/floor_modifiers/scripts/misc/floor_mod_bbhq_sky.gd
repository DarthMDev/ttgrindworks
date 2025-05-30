extends FloorModifier


func modify_floor() -> void:
	var skybox: Node3D = load('res://models/props/sky_boxes/bbhq_skybox.fbx').instantiate()
	var player: Player
	if not Util.get_player():
		player = await Util.s_player_assigned
	else:
		player = Util.get_player()
	player.add_child(skybox)
	skybox.scale *= 3.0

	# Set up fog
	var env: Environment = game_floor.environment.environment.duplicate()
	env.background_energy_multiplier = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color.BLACK
	env.fog_density = 0.008
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0f0f0f")
	game_floor.environment.environment = env

	# Await a process frame
	# Apparently game floor's tree exited signal is emitted on startup when direclty loading into the scene
	# Only affects debug but I don't like the sky not being there
	await get_tree().process_frame
	game_floor.tree_exited.connect(skybox.queue_free)

func get_mod_name() -> String:
	return "Bossbot Skybox"
