extends Node3D

signal s_dna_set

@export var skeleton: Skeleton3D
@export var animator: AnimationPlayer

@export_category('For Texturing')
@export var department_emblem: Sprite3D
@export var health_meter: MeshInstance3D

@export_category('External')
@export var nametag_node: Node3D
@export var nametag: Node3D
@export var head_node: Node3D
@export var skele_head: Node3D
@export var head_bone: BoneAttachment3D
@export var head_cone: BoneAttachment3D
@export var left_hand_bone: BoneAttachment3D
@export var right_hand_bone: BoneAttachment3D
@export var right_index_bone: BoneAttachment3D
@export var health_bone: BoneAttachment3D
@export var tie_mesh: MeshInstance3D
@export var color_overlay_meshes: Array[GeometryInstance3D]

var override_mats: Array[StandardMaterial3D] = []
var is_mod := false
var dna_set := false
var custom_nametag_height := 0.0
var body_color := Color.WHITE

var color_overlay_mat := ColorOverlayMaterial.new()

func set_dna(dna: CogDNA) -> void:
	scale *= dna.scale
	
	# Set up material overrides for every mesh
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			for i in child.mesh.get_surface_count():
				if not child.get_surface_override_material(i):
					var new_mat : StandardMaterial3D = child.mesh.surface_get_material(i).duplicate()
					child.set_surface_override_material(i, new_mat)
					override_mats.append(new_mat)
				else:
					child.set_surface_override_material(i, child.get_surface_override_material(i).duplicate())
					override_mats.append(child.get_surface_override_material(i))
	
	if tie_mesh:
		var tie_mat: StandardMaterial3D = tie_mesh.get_surface_override_material(0)
		match dna.department:
			CogDNA.CogDept.SELL: tie_mat.albedo_texture = load("res://models/cogs/textures/sell/cog_robot_tie_sales.png")
			CogDNA.CogDept.CASH: tie_mat.albedo_texture = load("res://models/cogs/textures/cash/cog_robot_tie_money.png")
			CogDNA.CogDept.LAW: tie_mat.albedo_texture = load("res://models/cogs/textures/law/cog_robot_tie_legal.png")
			CogDNA.CogDept.BOSS: tie_mat.albedo_texture = load("res://models/cogs/textures/boss/cog_robot_tie_boss.png")

	is_mod = dna.is_mod_cog
	custom_nametag_height = dna.custom_nametag_height
	dna_set = true
	s_dna_set.emit()
	
	for mesh: GeometryInstance3D in color_overlay_meshes:
		mesh.material_overlay = color_overlay_mat

# Colors every mesh of the body
func set_color(color: Color) -> void:
	body_color = color
	for mat in override_mats:
		mat.albedo_color = color
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

func flash_instant(color: Color, time: float = 0.2, strength: float = 0.7) -> void:
	if color_overlay_mat:
		color_overlay_mat.flash_instant(self, color, time, strength)

func flash(color: Color, time: float = 0.2, strength: float = 0.7) -> void:
	if color_overlay_mat:
		color_overlay_mat.flash(self, color, time, strength)
		
func print_head_node_info(dna) -> void:
	if head_node:
		print("Head Node Info:")
		print("Name: ", head_node.name)
		print("Type: ", head_node.get_class())
		head_node.get_path_to(head_node)
		head_node.print_tree_pretty()
		print("head's parent node:")
		print(head_node.get_parent_node_3d())
		#if head_node.get_parent_node_3d():
		#	dna.head = head_node.get_parent_node_3d()
		print("head_node path: ")
		print(head_node.get_path())
		if head_node.has_method("get_scene_file_path"):
			var scene_path = head_node.get_scene_file_path()

	else:
		print("No head_node assigned")
