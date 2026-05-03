extends CanvasLayer


@onready var seed_label: Label = %SeedLabel
@onready var root: Control = %Root
@onready var seed_button: Button = %SeedButton
@onready var node_viewer: TextureRect = %NodeViewer

var toon: Toon
var score_tally_tween: Tween

func _ready() -> void:
	if Util.get_player() and Util.get_player().character:
		var player_char: PlayerCharacter = Util.get_player().character
		var char_name: String
		if player_char.random_character_stored_name:
			char_name = player_char.random_character_stored_name
		else:
			char_name = player_char.character_name
		%Congratulation.set_text("%s defeated the Executive Office!" % char_name)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.time_scale = 1.0
	get_tree().paused = true
	root.modulate.a = 0.0

	seed_label.set_text("Seed: %s" % [RNG._str_seed if RNG._str_seed else str(RNG.base_seed)])
	seed_button.mouse_entered.connect(_hover_seed_label)
	seed_button.mouse_exited.connect(_stop_hover_seed_label)
	seed_button.pressed.connect(_seed_label_clicked)

	node_viewer.sub_viewport.size *= 2.0
	toon = load("res://objects/toon/toon.tscn").instantiate()
	node_viewer.add_child(toon)
	toon.drop_shadow.queue_free()
	reset_toon()

	
	Sequence.new([
		LerpProperty.new(root, ^"modulate:a", 1.0, 1.0).interp(Tween.EASE_IN, Tween.TRANS_QUAD)
	]).as_tween(self)

	%Quit.hide()
	score_tally_tween = create_score_tally_tween()
	%TotalLabel.set_text("[table=1][cell]Total Score[/cell][/table] %d" % ScoreTally.get_point_total())
	if is_instance_valid(Util.get_player()):
		%TimeLabel.set_text("Your time: " + Util.get_player().game_timer.get_time_string(Util.get_player().game_timer.time))
	
	if ScoreTally.get_point_total() > SaveFileService.progress_file.high_score:
		SaveFileService.progress_file.high_score = ScoreTally.get_point_total()
	
	if is_instance_valid(Util.get_player()):
		Util.get_player().queue_free()
	SaveFileService.delete_run_file()
	SaveFileService._save_progress()

func create_score_tally_tween() -> Tween:
	var tween: Tween = create_tween()
	var typewriter_time := 0.05 # Time between each character written
	var table_prefix := "[table=1][cell]"
	var table_suffix := "[/cell][/table] "
	var string := ""
	
	for channel in ScoreTally.get_active_categories():
		var points := ScoreTally.get_channel_score(channel)
		var channel_name: String = str(channel)
		match signi(points):
			# We do not count categories at 0 points
			0: continue
			# Channels that go negative can have special names
			-1:
				if channel in ScoreTally.negative_channels:
					channel_name = str(ScoreTally.negative_channels[channel])
		
		if not string.is_empty():
			string += "\n"
			tween.tween_callback(score_append.bind("\n"))
		var insertion_point := string.length() + table_prefix.length()
		string += table_prefix + str(channel_name) + table_suffix + str(points)
		tween.tween_callback(score_append.bind(table_prefix + table_suffix))
		
		# Animate the typewriter effect
		for chr in channel_name:
			tween.tween_interval(typewriter_time)
			tween.tween_callback(score_insert.bind(insertion_point, chr))
			insertion_point += 1
			tween.tween_callback(%TypeSFX.play)
		
		# Tally up the points, baby!!
		var point_count := 0
		var absolute_points := absi(points)
		var tally_rate := maxi(roundi(absolute_points / 750), 1)
		var sfx_scale := 1.0 + (float(tally_rate) * 0.12)
		var sfx_increment := (sfx_scale - 1.0) / roundf(points / tally_rate)
		if signi(points) == -1: tween.tween_callback(score_append.bind("-"))
		tween.tween_callback(%ScoreSFX.play)
		while point_count < absolute_points:
			tween.tween_interval(0.001)
			tween.tween_callback(score_trim_suffix.bind(str(point_count)))
			point_count += tally_rate
			tween.tween_callback(score_append.bind(str(point_count)))
			tween.tween_callback(func(): %ScoreSFX.pitch_scale += sfx_increment)
		tween.tween_callback(%ScoreSFX.stop)
		tween.tween_callback(func(): %ScoreSFX.pitch_scale = 1.0)
	
	#tween.tween_callback(%ApplauseSFX.play)
	var zoom_time := 0.3
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(%Quit.show)
	tween.tween_callback(%CelebrationSFX.play)
	tween.tween_property(%TotalLabel, 'self_modulate', Color("4de64d"), zoom_time)
	tween.parallel().tween_property(%TotalLabelScaler, 'scale', Vector2(1.1, 1.1), zoom_time)
	tween.tween_property(%TotalLabel, 'self_modulate', Color("ffffff"), zoom_time)
	tween.parallel().tween_property(%TotalLabelScaler, 'scale', Vector2.ONE, zoom_time)
	
	return tween

func score_insert(position: int, what: String) -> void:
	%ScoreLabel.text = %ScoreLabel.text.insert(position, what)

func score_append(what: String) -> void:
	%ScoreLabel.text += what

func score_trim_suffix(what: String) -> void:
	%ScoreLabel.text = %ScoreLabel.text.trim_suffix(what)

func exit() -> void:
	SceneLoader.load_into_scene("res://scenes/title_screen/title_screen.tscn")

func _exit_tree() -> void:
	get_tree().paused = false
	AudioManager.reset_music_pitch()

var _seed_ival: ActiveInterval

func _hover_seed_label() -> void:
	HoverManager.hover("Click to copy seed")
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color(0.4, 1, 1, 1)).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _stop_hover_seed_label() -> void:
	HoverManager.stop_hover()
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color.WHITE).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _seed_label_clicked() -> void:
	DisplayServer.clipboard_set(RNG._str_seed)
	HoverManager.hover("Seed copied!")
	AudioManager.play_sound(load("res://audio/sfx/ui/GUI_balloon_popup.ogg"), 10.0)
	seed_label.self_modulate = Color.ORANGE
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.6, Color(0.4, 1, 1, 1)).start(self)

func reset_toon() -> void:
	var dna: ToonDNA
	if not is_instance_valid(Util.get_player()):
		dna = ToonDNA.new()
		dna.randomize_dna()
	else:
		dna = Util.get_player().toon.toon_dna
		Util.get_player().hide()
	
	
	toon.construct_toon(dna)
	toon.set_animation('victory-dance')
	toon.rotation_degrees.y = 210.0
	toon.anim_seek(0.28, true)
	get_tree().create_timer(0.05).timeout.connect(toon.anim_pause)
	toon.set_blink_paused(true)

	await get_tree().process_frame
	node_viewer.remove_child(toon)
	await get_tree().process_frame
	node_viewer.node = toon
	node_viewer.camera.position.y += 0.2

	var species_name: String = ToonDNA.ToonSpecies.keys()[toon.toon_dna.species].to_lower()
	%TilingBackground.texture = load(Globals.laff_meters[species_name])
