"""
USAGE
Open a scene, then do Editor->File->Run
Currently only works on active materials & not overridden surfaces.
"""

@tool
extends EditorScript

func _run():
	var editor_interface = get_editor_interface()
	var edited_scene = editor_interface.get_edited_scene_root()

	if not edited_scene:
		print("No scene is currently open!")
		return

	var materials = []
	get_all_materials(edited_scene, materials)

	for material in materials:
		if material is StandardMaterial3D:
			material.use_vertex_color = true
			material.vertex_color_is_srgb = true  # Interpret vertex colors as sRGB
			material.resource_local_to_scene = true  # Avoid modifying shared resources

			print("Updated material:", material.resource_name)

func get_all_materials(node, materials):
	if node is MeshInstance3D:
		var surface_count = node.get_mesh().get_surface_count() if node.get_mesh() else 0
		for i in range(surface_count):
			var mat = node.get_active_material(i)
			print(mat)
			if mat and mat not in materials:
				materials.append(mat)
	
	for child in node.get_children():
		get_all_materials(child, materials)
