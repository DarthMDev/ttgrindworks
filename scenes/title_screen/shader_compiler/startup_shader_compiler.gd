extends Control

const STAY_TIME := 0.25

## These scenes will be forced to load on startup
@export_custom(GameLoader.FILE_ARRAY, GameLoader.SCENE_ARRAY) var files_to_load: Array[String] = []

@onready var object_node: Node = %LoadedObjects
@onready var progress_bar: ProgressBar = %ProgressBar

var loading_objects: Array[Node] = []


func _ready() -> void:
	progress_bar.max_value = files_to_load.size()
	for path in files_to_load:
		await Task.delay(0.1)
		load_object(path)

func load_object(path: String) -> void:
	var node: Node = load(path).instantiate()
	object_node.add_child(node)
	loading_objects.append(node)
	var particles: Array[Node] = NodeGlobals.get_children_of_type(node, GPUParticles3D, true)
	if node is GPUParticles3D: particles.append(node)
	for particle: GPUParticles3D in particles:
		particle.emitting = false
		particle.one_shot = false
		particle.preprocess = 10.0
		particle.emitting = true
	var timer := Timer.new()
	timer.wait_time = STAY_TIME
	node.add_child(timer)
	timer.start()
	timer.timeout.connect(finish_load.bind(node))

func finish_load(obj: Node) -> void:
	loading_objects.erase(obj)
	obj.queue_free()
	progress_bar.value += 1.0

func on_progress_changed(new_val: float) -> void:
	if is_equal_approx(new_val, progress_bar.max_value):
		compilation_done()

func compilation_done() -> void:
	SceneLoader.load_into_scene("res://scenes/title_screen/title_screen.tscn")
