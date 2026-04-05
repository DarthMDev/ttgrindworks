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
@export var head_bone: BoneAttachment3D
@export var left_hand_bone: BoneAttachment3D
@export var right_hand_bone: BoneAttachment3D
@export var right_index_bone: BoneAttachment3D
@export var health_bone: BoneAttachment3D
@export var shadow_bone: BoneAttachment3D
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
					var new_mat : StandardMaterial3D = child.mesh.surface_get_material(i).duplicate(true)
					child.set_surface_override_material(i, new_mat)
					override_mats.append(new_mat)
				else:
					child.set_surface_override_material(i, child.get_surface_override_material(i).duplicate(true))
					override_mats.append(child.get_surface_override_material(i))
	
	if tie_mesh:
		var tie_mat: StandardMaterial3D = tie_mesh.get_surface_override_material(0)
		if get_custom_texture(dna, 'custom_skelecog_tie_tex'):
			tie_mat.albedo_texture = get_custom_texture(dna, 'custom_skelecog_tie_tex')
		else:
			match dna.department:
				CogDNA.CogDept.SELL: tie_mat.albedo_texture = load("res://models/cogs/textures/sell/cog_robot_tie_sales.png")
				CogDNA.CogDept.CASH: tie_mat.albedo_texture = load("res://models/cogs/textures/cash/cog_robot_tie_money.png")
				CogDNA.CogDept.LAW: tie_mat.albedo_texture = load("res://models/cogs/textures/law/cog_robot_tie_legal.png")
				CogDNA.CogDept.BOSS: tie_mat.albedo_texture = load("res://models/cogs/textures/boss/cog_robot_tie_boss.png")

	if department_emblem:
		if get_custom_texture(dna, 'custom_emblem_tex'):
			department_emblem.set_texture(get_custom_texture(dna, 'custom_emblem_tex'))
		else:
			department_emblem.set_texture(get_department_emblem(dna.department))

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

static func get_custom_texture(dna : CogDNA, value : StringName) -> Texture2D:
	if not value in dna:
		return null
	var tex: Texture2D
	
	var tex_path: String = dna.get(value)
	if tex_path:
		tex = load(tex_path)
	
	if not tex_path:
		if dna.external_assets.has(value):
			if dna.external_assets.get(value) is String:
				if dna.external_assets.get(value).begins_with("res://"):
					tex = load(dna.external_assets.get(value))
				else:
					tex = ImageTexture.create_from_image(Image.load_from_file(dna.external_assets.get(value)))
	return tex

static func get_department_emblem(dept: CogDNA.CogDept) -> Texture2D:
	# Return bossbot as failsafe
	if dept == CogDNA.CogDept.NULL:
		return load("res://models/cogs/misc/hp_light/boss.png")
	return load("res://models/cogs/misc/hp_light/" + Cog.get_department_name(dept) + ".png")
