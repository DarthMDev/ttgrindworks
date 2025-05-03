"""
USAGE
Editor->File->Run

If TRD broke all the button's rotations by 90 degrees,
use this script to fix them.
"""

@tool
extends EditorScript

func collect_scene_paths(path: String, scene_paths: PackedStringArray):
	for entry in ResourceLoader.list_directory(path):
		if path.begins_with('res://addons'):
			continue
		elif entry.ends_with("/"):
			collect_scene_paths(path + entry, scene_paths)
		elif entry.ends_with('.tscn'):
			scene_paths.append(path + entry)

func collect_scenes_with_buttons() -> PackedStringArray:
	var cog_button: PackedScene = load('res://objects/interactables/button/button.tscn')
	var pressure_button: PackedScene = load('res://objects/interactables/pressure_button/pressure_button.tscn')
	var buttons := [cog_button, pressure_button]
	
	var all_scene_paths: PackedStringArray
	var scene_paths: PackedStringArray
	collect_scene_paths('res://', all_scene_paths)
	for path in all_scene_paths:
		if path == cog_button.resource_path or path == pressure_button.resource_path:
			continue
		var scene: PackedScene = load(path)
		var state := scene.get_state()
		for i in range(state.get_node_count()):
			if state.get_node_instance(i) in buttons:
				scene_paths.append(path)
	return scene_paths

func fix_scenes_with_buttons(scene_paths: PackedStringArray):
	for path in scene_paths:
		var packed_scene: PackedScene = load(path)
		var scene: Node = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		for child: Node3D in scene.find_children('*', 'Node3D'):
			if child is CogButton or child is PressureButton:
				child.rotation_degrees.x = 0
		packed_scene.pack(scene)
		ResourceSaver.save(packed_scene)
	
func _run():
	var scenes_with_buttons := collect_scenes_with_buttons()
	fix_scenes_with_buttons(scenes_with_buttons)
