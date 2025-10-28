extends Node
## Runs through all Texture2D png files in resources and removes associated normal data.

func _ready() -> void:
	run()

static func get_script_name() -> String:
	return "replace_normals"

static func run() -> String:
	var all_texture_filepaths: Array[String] = PathLoader.load_filepaths("res://models/toon/body/", ".fbx", true, PackedScene)
	all_texture_filepaths.assign(all_texture_filepaths.map(func(x: String): return x + ".import"))
	

	for tex_path: String in all_texture_filepaths:
		var import_file: ConfigFile = ConfigFile.new()
		var load_result = import_file.load(tex_path)
		if load_result == ERR_FILE_CANT_OPEN:
			continue
		import_file.get_value("params", "_subresources", {}).get_or_add("nodes", {}).get_or_add("PATH:AnimationPlayer", {})["optimizer/enabled"] = false
		#import_file.set_value("params", "compress/normal_map", 2)
		#import_file.set_value("params", "roughness/src_normal", "")
		import_file.save(tex_path)

	return "Removed normal data for %s Texture2D pngs." % all_texture_filepaths.size()
