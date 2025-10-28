extends TextureRect
class_name DirectoryViewer

const FILE_DISPLAYER := preload("res://scenes/cog_creator/file_template.tscn")
const ALLOWED_MODELS := ["glb", "gltf"]
const ALLOWED_TEXTURES := ["png", "jpg", "svg"]

@export var directory := "res://"
@export var save_dir := ""
@export var allowed_types : Array[String]
@export var allow_custom := true

@onready var file_grid : GridContainer = $ScrollContainer/GridContainer
@onready var load_panel : TextureRect = $LoadPanel
@onready var load_button : GeneralButton = $FooterButtons/OpenButton
@onready var allowed_types_label : Label = $LoadPanel/AllowedTypes

var selected_file : String
var files : Array[UIFile] = []
var awaiting_load := false

signal s_file_opened(file : String)
signal s_file_selected(file : String)
signal s_file_imported(file : Variant, file_name : String)
signal s_loading_files
signal s_finished_loading


func _ready() -> void:
	set_directory(directory)
	get_viewport().files_dropped.connect(on_files_dropped)
	
	if not allow_custom:
		load_button.hide()
	
	set_up_save_dir()
	
	for type in allowed_types:
		allowed_types_label.text += " .%s" % type

func set_directory(dir : String) -> void:
	if not dir.ends_with("/"):
		dir += "/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	directory = dir
	get_files()
	populate_menu()

func show_custom_file_list(list : Array[UIFile]) -> void:
	files = list.duplicate(true)
	populate_menu()

func set_up_save_dir() -> void:
	if not save_dir == "":
		if not DirAccess.dir_exists_absolute(save_dir):
			DirAccess.make_dir_recursive_absolute(save_dir)

func get_files() -> void:
	return

func populate_menu() -> void:
	for child in file_grid.get_children():
		child.queue_free()
	
	for file in files:
		var displayer := FILE_DISPLAYER.instantiate()
		file_grid.add_child(displayer)
		displayer.set_file(file)
		displayer.s_selected.connect(select_file.bind(displayer))

func select_file(displayer : FileDisplayer) -> void:
	selected_file = displayer.file.file_path
	s_file_selected.emit(displayer.file)

func open_load_panel() -> void:
	awaiting_load = true
	load_panel.show()

func cancel_load() -> void:
	awaiting_load = false
	if load_panel:
		load_panel.hide()

func on_files_dropped(dragged_files : PackedStringArray) -> void:
	if not awaiting_load:
		return
	s_loading_files.emit()
	for file : String in dragged_files:
		var file_copy := create_copy(file)
		var loaded_file : Variant = attempt_load(file_copy)
		if not loaded_file == null:
			s_file_imported.emit(loaded_file, file_copy)
		else:
			DirAccess.remove_absolute(file_copy)
	s_finished_loading.emit()

func attempt_load(file : String) -> Variant:
	if not file.get_extension() in allowed_types:
		return null
	if file.get_extension() in ALLOWED_MODELS:
		return load_model(file)
	elif file.get_extension() in ALLOWED_TEXTURES:
		return load_texture(file)
	return null

func load_model(file : String) -> Node3D:
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	if gltf_doc.append_from_file(file, gltf_state) == OK:
		var gltf_scene : Node3D = gltf_doc.generate_scene(gltf_state)
		
		return gltf_scene
	return null

func load_texture(file : String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(file))

func create_copy(file : String) -> String:
	var base_name := file.get_file()
	DirAccess.copy_absolute(file, save_dir + base_name)
	return save_dir + base_name

func on_visibility_changed() -> void:
	if not is_visible_in_tree():
		cancel_load()
