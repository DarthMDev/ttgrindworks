extends Control

const CAMERA_SPEED := 10.0
const TOON_SEPARATION := 1.0
var TOON: PackedScene
var PLAYER: PackedScene
var SETTINGS_MENU: PackedScene
var EXTRAS_MENU: PackedScene
var ELEVATOR_SCENE: PackedScene

var SFX_SELECT: AudioStreamOggVorbis
var RELEASES_MENU: PackedScene


enum MenuState {
	ROTATING,
	TRANSITIONING,
	TOON_SELECT,
	TOON_FOCUS,
	NEW_GAME,
}
@export var state := MenuState.ROTATING:
	set(x):
		state = x
		update_state()

@export var toon_collision: CapsuleShape3D

@onready var spring_arm: SpringArm3D = $World3D/SpringArm
@onready var toon_origin: Node3D = $World3D/ToonOrigin
@onready var building: Node3D = %CogBuilding
@onready var new_game_menu: Control = %NewGameMenu
@onready var new_game_button: GeneralButton = %NewGameButton
@onready var continue_button: GeneralButton = %ContinueButton
@onready var settings_button: GeneralButton = %SettingsButton
@onready var quit_button: GeneralButton = %QuitButton
@onready var toon_summary: Control = %ToonSummary
@onready var click_label := %ClickLabel
@onready var middle_buttons: VBoxContainer = %MiddleButtons

var selected_toon: Toon
var selected_character: PlayerCharacter
var random_toon_name := ""
var elevator: BuildingElevator

@onready var click_label_text: String = %ClickLabel.text
var releases_menu: UIPanel = null

var has_existing_run: bool:
	get: return SaveFileService.run_file != null

var is_loading := true

func _init():
	GameLoader.queue_into(GameLoader.Phase.GAME_START, self, {
		'SETTINGS_MENU': 'res://objects/general_ui/settings_menu/settings_menu.tscn',
		'EXTRAS_MENU': 'res://scenes/title_screen/extras_menu.tscn',
		'SFX_SELECT': 'res://audio/sfx/ui/Click.ogg',
		'RELEASES_MENU': 'res://scenes/title_screen/release_notes/release_notes_panel.tscn',
	})
	GameLoader.queue_into(GameLoader.Phase.AVATARS, self, {
		'TOON': 'res://objects/toon/toon.tscn',
	})
	GameLoader.queue_into(GameLoader.Phase.PLAYER, self, {
		'PLAYER': 'res://objects/player/player.tscn',
		'ELEVATOR_SCENE': 'res://scenes/elevator_scene/elevator_scene.tscn',
	})
	
	GameLoader.load_all()

func _ready() -> void:
	Engine.time_scale = 1.0
	
	Util.stuck_lock = false
	
	# If we have a stored character from a "try again" lose prompt,
	# throw it in here so that they will be in the cog building
	if Util.stored_try_again_char_name:
		for character: PlayerCharacter in Globals.fetch_toon_unlock_order():
			if character.character_name == Util.stored_try_again_char_name:
				character = character.duplicate()
				if character.character_name == "RandomToon":
					character.dna.randomize_dna()
					character.random_character_stored_name = Globals.get_random_toon_name()
				Util.stored_try_again_char_name = ""
				begin_game(character, true)
				return

	Util.circle_in.call_deferred.bind(10.0)
	
	if building:
		if building.sellbot_elevator:
			elevator = building.sellbot_elevator
	
	if has_existing_run:
		elevator.floor_current = clamp(SaveFileService.run_file.floor_number + 1, 0, 6)
	else:
		continue_button.set_disabled(true)
		continue_button.material.set_shader_parameter('alpha', 0.4)
		continue_button.get_node("Label").self_modulate = Color(1, 1, 1, 0.6)
	
	quit_button.pressed.connect(
		func():
			SaveFileService._save_progress()
			get_tree().quit()
	)
	
	%ClickLabel.text = 'Loading...'
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	random_toon_name = Globals.get_random_toon_name()
	
	Util.floor_number = -1

	var fade_tween := create_tween()
	fade_tween.tween_property(click_label, 'self_modulate:a', 0.0, 1.0)
	fade_tween.tween_property(click_label, 'self_modulate:a', 1.0, 1.0)
	fade_tween.set_loops()

	%VersionLabel.set_text(Globals.VERSION_NUMBER)
	
	AudioManager.stop_music(true)
	AudioManager.set_default_music(load("res://audio/music/main_theme.ogg"))
	
	Globals.s_title_screen_entered.emit(self)
	check_for_new_version()

func _process(delta: float) -> void:
	if state == MenuState.ROTATING:
		spring_arm.rotation_degrees.y += CAMERA_SPEED * delta
		if spring_arm.rotation_degrees.y - 360.0 > 0:
			spring_arm.rotation_degrees.y -= 360.0
		
		if is_loading:
			is_loading = false
			%ClickLabel.label_settings.font_color = Color.WHITE
			%ClickLabel.text = click_label_text

func _input_rotating(event) -> void:
	if is_loading:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			play_pressed()

func gui_input(event: InputEvent) -> void:
	if state == MenuState.ROTATING:
		_input_rotating(event)

func play_pressed() -> void:
	$GUI/Logo.hide()
	state = MenuState.TRANSITIONING
	var center_tween := create_tween()
	center_tween.set_trans(Tween.TRANS_QUAD)
	center_tween.tween_property(spring_arm, 'rotation_degrees', Vector3(-10.0, 0, 0), 1.0)
	center_tween.parallel().tween_property(spring_arm, 'position', Vector3(0.0, 1.5, 4.0), 1.0)
	center_tween.parallel().tween_property(spring_arm, 'spring_length', 2.5, 1.0)
	await center_tween.finished
	center_tween.kill()
	state = MenuState.NEW_GAME
	new_game_menu.show()

func create_toons() -> void:
	await GameLoader.wait_for_phase(GameLoader.Phase.AVATARS)
	var toons := get_character_list()
	
	var starting_point := (-floorf(toons.size() / 2)) * TOON_SEPARATION
	if toons.size() % 2 == 0: starting_point += (TOON_SEPARATION / 2.0)
	
	for character : PlayerCharacter in toons:
		await Task.delay(0.25)
		var toon := spawn_toon(character)
		toon_origin.add_child(toon)
		toon.construct_toon(toon.toon_dna)
		toon.position.x = starting_point
		starting_point += TOON_SEPARATION
		toon.teleport_in()
		toon.animator.animation_finished.connect(toon.animator.play.bind('neutral').unbind(1))

func get_character_list() -> Array[PlayerCharacter]:
	return Globals.get_unlocked_toons()

func spawn_toon(character : PlayerCharacter) -> Toon:
	var toon := TOON.instantiate()
	toon.toon_dna = character.dna
	if character.character_name == "RandomToon":
		randomize()
		toon.toon_dna.randomize_dna()
		RandomService.randi_channel('true_random')
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = toon_collision
	static_body.add_child(collision_shape)
	toon.add_child(static_body)
	static_body.input_event.connect(toon_input_event.bind(toon, character))
	return toon

func toon_input_event(_camera, event, _event_position, _normal, _shape_index, toon: Toon, character: PlayerCharacter) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if state == MenuState.TOON_SELECT and toon.animator.current_animation == "neutral":
				toon_clicked(toon, character)

func toon_clicked(toon: Toon, character: PlayerCharacter) -> void:
	selected_character = character
	selected_toon = toon
	toon.set_animation('happy')
	AudioManager.play_sound(SFX_SELECT)
	set_selected_toon(character)

func toon_canceled() -> void:
	toon_summary.hide()
	%PickAToonLabel.show()

func new_game() -> void:
	state = MenuState.TRANSITIONING
	var toon_tween := create_tween()
	toon_tween.tween_callback(make_toon_look.bind(selected_toon, elevator.player_pos.global_position))
	toon_tween.tween_callback(selected_toon.set_animation.bind('run'))
	toon_tween.tween_property(selected_toon, 'global_position', elevator.player_pos.global_position, 1.0)
	toon_tween.tween_callback(selected_toon.set_rotation.bind(Vector3.ZERO))
	toon_tween.tween_callback(selected_toon.set_animation.bind('neutral'))
	if SaveFileService.settings_file.skip_intro:
		alt_opening(toon_tween)
	else:
		toon_tween.tween_callback(elevator.close)
		toon_tween.tween_interval(3.0)
	await toon_tween.finished
	toon_tween.kill()
	if SaveFileService.settings_file.skip_intro:
		begin_game(selected_character, true)
	else:
		begin_game(selected_character)

func make_toon_look(toon: Toon, where: Vector3) -> void:
	toon.look_at(where)
	toon.rotation_degrees = Vector3(0, toon.rotation_degrees.y - 180.0 , 0)

func begin_game(character: PlayerCharacter, falling_scene := false) -> void:
	if has_existing_run:
		SaveFileService.progress_file.win_streak = 0

	SaveFileService.delete_run_file()
	RandomService.generate_seed()
	Util.floor_number = -1
	await GameLoader.wait_for_phase(GameLoader.Phase.PLAYER)
	# Create the player object
	var player: Player = PLAYER.instantiate()
	player.stats = PlayerStats.new()
	player.stats.character = character.duplicate(true)
	player.reset_stats()
	SceneLoader.add_persistent_node(player)
	player.stats.max_out()
	SaveFileService.progress_file.new_games += 1
	if falling_scene:
		SceneLoader.load_into_scene("res://scenes/falling_scene/falling_scene.tscn", GameLoader.Phase.FALLING_SEQ)
	else:
		SceneLoader.load_into_scene("res://scenes/cog_building/cog_building_floor.tscn", GameLoader.Phase.COG_BLDG_FLOOR)

func update_state() -> void:
	new_game_menu.visible = (state == MenuState.TOON_SELECT or state == MenuState.NEW_GAME)
	toon_summary.hide()

func open_settings() -> void:
	get_tree().get_root().add_child(SETTINGS_MENU.instantiate())

func open_extras() -> void:
	get_tree().get_root().add_child(EXTRAS_MENU.instantiate())

func open_releases() -> void:
	if not releases_menu:
		releases_menu = RELEASES_MENU.instantiate()
		get_tree().get_root().add_child(releases_menu)
		releases_menu.tree_exited.connect(func(): releases_menu = null)

func load_game() -> void:
	SaveFileService.load_run()
	%NewGameButton.disabled = true
	%ContinueButton.disabled = true
	await GameLoader.wait_for_phase(GameLoader.Phase.PLAYER)
	var player: Player = PLAYER.instantiate()
	player.stats = SaveFileService.run_file.player_stats
	player.stats.character.dna = SaveFileService.run_file.player_dna
	player.stats.initialize()
	SceneLoader.add_persistent_node(player)
	player.game_timer.time = SaveFileService.run_file.game_time
	ItemService.apply_inventory()
	SceneLoader.load_into_scene(
		"res://scenes/elevator_scene/elevator_scene.tscn",
		GameLoader.Phase.GAMEPLAY
	)

func set_selected_toon(character: PlayerCharacter) -> void:
	%ToonName.label_settings.font_color = character.dna.head_color
	toon_summary.show()
	if character.character_name == "RandomToon":
		%ToonName.set_text(random_toon_name)
		character.random_character_stored_name = random_toon_name
	else:
		%ToonName.set_text(character.character_name)
	%SummaryDesc.set_text(character.get_true_summary())
	%PickAToonLabel.hide()

var toons_created := false
func new_game_pressed() -> void:
	middle_buttons.hide()
	state = MenuState.TOON_SELECT
	if not toons_created:
		create_toons()
		toons_created = true

func back_pressed() -> void:
	if not middle_buttons.visible:
		middle_buttons.show()
		state = MenuState.NEW_GAME
		toon_summary.hide()
	else:
		back_out_logo()

func back_out_logo() -> void:
	state = MenuState.TRANSITIONING
	new_game_menu.hide()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(spring_arm, 'spring_length', 24.0, 2.5)
	tween.parallel().tween_property(spring_arm, 'rotation_degrees', Vector3(-22.0, 0, 0), 1.0)
	tween.parallel().tween_property(spring_arm, 'position', Vector3(0.0, 5.0, 8.02), 1.0)
	tween.finished.connect(
		func():
			tween.kill()
			$GUI/Logo.show()
			state = MenuState.ROTATING
	)

@onready var elevator_floor := $World3D/CogBuilding/suit_landmark_new_corp/locators/suit_landmark_new_corp_door_origin/GeometryTransformHelper11/sellbot_elevator/suit_elevator_1/ground
func alt_opening(tween : Tween) -> void:
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(elevator_floor, 'rotation_degrees:x', -90.0, 0.25)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/sequences/elevator_trick/elevator_trick_open.ogg")))
	tween.tween_callback(AudioManager.tween_music_pitch)
	tween.tween_interval(0.2)
	tween.tween_callback(AudioManager.stop_music.bind(true))
	tween.tween_callback(AudioManager.reset_music_pitch)
	tween.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/sequences/elevator_trick/elevator_trick_riser.ogg")))
	tween.tween_callback(selected_toon.set_animation.bind('melt_nosink'))
	tween.tween_interval(1.0)
	tween.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/sequences/elevator_trick/elevator_trick_react.ogg")))
	tween.tween_callback(selected_toon.set_emotion.bind(Toon.Emotion.SAD))
	tween.tween_callback(selected_toon.animator.set_speed_scale.bind(-1.0))
	tween.tween_interval(1.0)
	tween.tween_callback(selected_toon.animator.set_speed_scale.bind(1.0))
	tween.tween_interval(1.0)
	tween.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/sequences/elevator_trick/elevator_trick_fall.ogg")))
	tween.tween_callback(selected_toon.set_animation.bind('melt_nosink'))
	tween.tween_callback(selected_toon.animator.seek.bind(2.0))
	tween.tween_property(selected_toon, 'position:y', -10.0, 0.6)


func check_for_new_version() -> void:
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://api.github.com/repos/ToontownGrindworks/grindworks/releases/latest")

func _on_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		print("Failed to check latest game version.")
		return
	var version = json["tag_name"]
	if version == Globals.VERSION_NUMBER:
		print("you are on the newest version. hooray!!!")
	else:
		print("new version is available. what is wrong with you??")
		%NewVersionLabel.show()
