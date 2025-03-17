extends BattleStartMovie
class_name LavaBossMovie


## WILL ONLY WORK IN THE LAVA BOSS ROOM
func _skip() -> void:
	super()
	await BattleService.s_battle_started
	var characters: Array[Node3D] = []
	characters.append_array(cogs)
	characters.append(Util.get_player())
	for partner in Util.get_player().partners:
		characters.append(partner)
	for character in characters:
		character.position.y = 0.0

func play() -> Tween:
	# Failsafe for if added to a different fight
	var manager: Node3D = battle_node.find_child('LavaBossManager')
	if not manager: 
		super()
		return
	
	# Get the player's value
	var player := Util.get_player()
	
	# Reparent camera before starting
	camera.reparent(battle_node)
	
	# Put player at starting position
	player.global_position = manager.player_spawn.global_position
	player.face_position(manager.ledge_pos.global_position)
	
	## MOVIE START
	movie = create_tween()
	
	# Set cam angle
	movie.tween_callback(set_camera_angle.bind(manager.intro_pos))
	
	# Toon walks to ledge
	movie.tween_callback(player.set_animation.bind('run'))
	movie.tween_property(player,'global_position',manager.ledge_pos.global_position,1.5)
	movie.tween_callback(player.set_animation.bind('neutral'))
	
	# Toon looks surprised
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.SURPRISE))
	movie.tween_interval(3.0)
	movie.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.NEUTRAL))
	
	# Cogs Turn Around
	movie.tween_callback(battle_node.focus_cogs)
	movie.tween_callback(focus_cog.speak.bind("You'd be wise not to come over here, Toon."))
	movie.set_parallel(true)
	for cog in cogs:
		movie.tween_callback(cog.set_animation.bind('walk'))
		movie.tween_property(cog,'rotation_degrees:y',0.0,2.0)
	movie.set_trans(Tween.TRANS_QUAD)
	movie.tween_property(camera,'position:z',3.0,2.0).as_relative()
	movie.set_trans(Tween.TRANS_LINEAR)
	movie.set_parallel(false)
	for cog in cogs:
		movie.tween_callback(cog.set_animation.bind('neutral'))
	movie.tween_interval(4.0)
	
	# Make Toon jump to the platform
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.tween_callback(player.set_animation.bind('happy'))
	movie.tween_interval(0.4)
	
	# Create jump path
	var path = Path3D.new()
	var curve := Curve3D.new()
	var follower = PathFollow3D.new()
	battle_node.add_child(path)
	path.curve = curve
	curve.bake_interval = 2.0
	path.add_child(follower)
	follower.rotation_mode = PathFollow3D.ROTATION_NONE
	var points : Array[Vector3] = [
		manager.ledge_pos.global_position,
		manager.jump_pos.global_position,
		manager.land_pos.global_position
	]
	for point in points:
		path.global_position = point
		curve.add_point(path.position)
	path.global_position = player.global_position
	
	
	movie.tween_callback(player.reparent.bind(follower))
	movie.tween_callback(player.set_position.bind(Vector3(0,0,0)))
	movie.tween_callback(path.set_position.bind(Vector3(0,0,0)))
	movie.tween_property(follower,'progress_ratio',1.0,0.7)
	
	# Reparent player to platform and delete the path 
	movie.tween_callback(player.reparent.bind(battle_node))
	movie.tween_callback(path.queue_free)
	movie.tween_interval(1.0)
	
	# Cog Dialogue
	movie.tween_callback(battle_node.focus_character.bind(focus_cog))
	movie.tween_callback(focus_cog.speak.bind("Now you've done it."))
	movie.tween_interval(4.0)
	
	# View the platform as it sinks
	movie.tween_callback(set_camera_angle.bind(manager.sink_pos))
	movie.tween_callback(manager.sink_platform.bind(1.0))
	movie.tween_interval(4.0)
	
	# Cog Dialogue finisher
	movie.tween_callback(battle_node.focus_character.bind(focus_cog))
	movie.tween_callback(focus_cog.speak.bind("Getting a sinking feeling?"))
	movie.tween_interval(4.0)
	
	# Start the battle music
	movie.tween_callback(start_music)
	
	return movie

func set_camera_angle(node : Node3D) -> void:
	battle_node.battle_cam.global_transform = node.global_transform
