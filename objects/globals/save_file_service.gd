extends Node

## MANAGES THE USER FILES
## Includes:
## - Settings File
## - Progress File
## - Current Run File

const SAVE_FILE_PATH := 'user://save/'
const RUN_FILE_NAME := 'current_save.tres'
const GLOBALSAVE_FILE_NAME := 'progress.tres'
const SETTINGS_FILE_NAME := 'settings.tres'
var ACHIEVEMENT_UI: PackedScene
var SAVE_GAME_TEXT: PackedScene

var run_file: SaveFile
var progress_file: ProgressFile
var settings_file: SettingsFile

var achievement_ui: Control

signal s_game_loaded
signal s_reset
signal s_settings_changed


func _init():
	GameLoader.queue_into(GameLoader.Phase.GAME_START, self, {
		'ACHIEVEMENT_UI': 'res://objects/general_ui/achievement_notification/achievement_ui.tscn',
		'SAVE_GAME_TEXT': 'res://objects/save_file/save_game_text.tscn',
	})

func save():
	_save_run()
	_save_progress()
	_show_save_text()

func _save_run() -> void:
	if not run_file:
		run_file = SaveFile.new()
	run_file.get_run_info()
	run_file.save_to(RUN_FILE_NAME)
	print("Run file saved")


func _save_progress() -> void:
	progress_file.save_to(GLOBALSAVE_FILE_NAME)
	print("Progress file saved")

func save_settings() -> void:
	settings_file.save_to(SETTINGS_FILE_NAME)
	print("Settings file saved")
	SaveFileService.s_settings_changed.emit()

func get_player_state() -> PlayerStats:
	if Util.get_player() and is_instance_valid(Util.get_player()):
		return Util.get_player().stats
	else:
		return null

func delete_run_file() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH+RUN_FILE_NAME):
		DirAccess.remove_absolute(SAVE_FILE_PATH+RUN_FILE_NAME)
	
	run_file = null
	s_reset.emit()

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_FILE_PATH):
		DirAccess.make_dir_absolute(SAVE_FILE_PATH)
	
	# Load our progress
	var progress_result := load_progress()
	
	# Set up our achievement listener
	achievement_ui = ACHIEVEMENT_UI.instantiate()
	add_child(achievement_ui)
	
	# Let progress file start listening
	progress_file.start_listening()
	
	# Load our settings
	var settings_result := load_settings()
	settings_file.sync_settings()
	
	# Load the player's current save file
	var run_result := load_run()
	
	var invalid_files : Array[String] = [progress_result, settings_result, run_result]
	for entry in invalid_files.duplicate():
		if entry == "" : invalid_files.erase("")
	
	if not invalid_files.is_empty():
		show_save_errors(invalid_files)

func load_settings() -> String:
	var file_path := SAVE_FILE_PATH + SETTINGS_FILE_NAME
	if FileAccess.file_exists(file_path):
		var file = ResourceLoader.load(file_path)
		if not file:
			save_file_error(file_path)
			return file_path
		settings_file = file
	if not settings_file:
		settings_file = SettingsFile.new()
	return ""

func load_progress() -> String:
	var file_path := SAVE_FILE_PATH + GLOBALSAVE_FILE_NAME
	# Look for the global progress file
	if FileAccess.file_exists(file_path):
		var file = ResourceLoader.load(file_path)
		if not file:
			save_file_error(file_path)
			return file_path
		progress_file = file
	# Should create the file
	if not progress_file:
		progress_file = ProgressFile.new()
	return ""

func load_run() -> String:
	var file_path := SAVE_FILE_PATH + RUN_FILE_NAME
	# Try to get the current run
	if FileAccess.file_exists(file_path):
		var test_file = ResourceLoader.load(file_path)
		if not test_file:
			save_file_error(file_path)
			return file_path
		var file = ResourceLoader.load(file_path, "", ResourceLoader.CacheMode.CACHE_MODE_IGNORE).duplicate()
		if file is SaveFile:
			run_file = file
			s_game_loaded.emit()
	if not run_file:
		return ""
	RandomService.base_seed = (run_file.current_seed)
	RandomService.channels = run_file.seed_channels
	Util.floor_number = run_file.floor_number
	ItemService.seen_items = run_file.seen_items
	ItemService.items_in_play = run_file.items_in_play
	return ""


func on_game_over() -> void:
	delete_run_file()
	run_file = null

func _process(delta : float) -> void:
	progress_file.total_playtime += delta / Engine.time_scale
	
	#if Input.is_action_just_pressed('save'):
	#	save()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()

func make_progress(property : String, value : Variant) -> void:
	if property in progress_file:
		progress_file.set(property, value)

func _show_save_text() -> void:
	var save_text_instance = SAVE_GAME_TEXT.instantiate()
	add_child(save_text_instance)

	var label = save_text_instance.get_node("Label")
	var tween = create_tween()

	tween.tween_property(label, "modulate:a", 1, 1.0)
	tween.tween_property(label, "modulate:a", 1, 2.0)
	tween.tween_property(label, "modulate:a", 0, 1.0)
	tween.finished.connect(_on_tween_all_completed.bind(save_text_instance))

func _on_tween_all_completed(save_text_instance):
	save_text_instance.queue_free()

func save_file_error(file_path : String) -> void:
	DirAccess.copy_absolute(file_path, file_path.trim_suffix(".tres") + "_BROKEN.tres")
	DirAccess.remove_absolute(file_path)

func is_achievement_unlocked(achievement: ProgressFile.GameAchievement) -> bool:
	if not progress_file: return false
	if not progress_file.achievements_earned.has(achievement): return false
	return progress_file.achievements_earned[achievement]

const SAVE_ERROR_PANEL := "res://objects/general_ui/ui_panel/misc_panels/save_error_panel/save_error_panel.tscn"
func show_save_errors(invalid_paths : Array[String]) -> void:
	await get_tree().process_frame
	var error_panel : UIPanel = GameLoader.load(SAVE_ERROR_PANEL).instantiate()
	get_tree().get_root().add_child(error_panel)
	error_panel.sync_faulty_files(invalid_paths)
