extends Control

const TIP_FILE := "res://scenes/loading_screen/tips.txt"

@onready var tip_label := $TipScroll/TipLabel


func _ready() -> void:
	if FileAccess.file_exists(TIP_FILE):
		var file_as_string := FileAccess.get_file_as_string(TIP_FILE)
		var file_as_array := file_as_string.split("\n")
		file_as_array.remove_at(file_as_array.size() - 1)
		tip_label.set_text(
		"TOON TIP:\n" + 
		file_as_array[RandomService.randi_channel('true_random') % file_as_array.size()]
		)

func load_scene(scene_path: String, load_phase: GameLoader.Phase = GameLoader.Phase.GAME_START) -> void:
	$ProgressBar.value = GameLoader.get_load_progress(load_phase)
	ResourceLoader.load_threaded_request(scene_path)
	while not $ProgressBar.value >= 1.0:
		await get_tree().process_frame
		$ProgressBar.value = GameLoader.get_load_progress(load_phase)
	
	var percentage_arr := []
	while ResourceLoader.load_threaded_get_status(scene_path, percentage_arr) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		$ProgressBar.value = percentage_arr[0]
	
	SceneLoader.change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
