extends Node3D

enum ToonPose {
	VICTORY
}
var pose := ToonPose.VICTORY
const POSE_ANIMS := {
	ToonPose.VICTORY : 'victory_dance'
}
const POSE_TIMES := {
	ToonPose.VICTORY : 4.3667
}

const TOON_SCALE := 2.45
const STONE_TEX := preload("res://models/props/gags/statue/textures/smoothwall_1.png")
const SHIRT_TEX := preload("res://models/toon/textures/clothes/shirts/desat_shirt_1_4.png")
const SLEEVE_TEX := preload("res://models/toon/textures/clothes/shirts/desat_sleeve_1.png")
const SHORTS_TEX := preload("res://models/toon/textures/clothes/shorts/desat_shorts_1_5.png")
const SKIRT_TEX := preload("res://models/toon/textures/clothes/skirts/desat_skirt_1_4.png")


@onready var toon : Toon = $Toon


func _ready() -> void:
	if is_instance_valid(Util.get_player()):
		toon.toon_dna = Util.get_player().toon.toon_dna
	else:
		toon.toon_dna.randomize_dna()
	toon.construct_toon(toon.toon_dna)
	toon.scale *= TOON_SCALE
	retexture_toon()
	color_toon()
	pose_toon()

func retexture_toon() -> void:
	toon.body.shirt.get_surface_override_material(0).albedo_texture = SHIRT_TEX
	toon.body.sleeve_left.get_surface_override_material(0).albedo_texture = SLEEVE_TEX
	if toon.toon_dna.skirt:
		toon.body.bottoms.get_surface_override_material(0).albedo_texture = SKIRT_TEX
	else:
		toon.body.bottoms.get_surface_override_material(0).albedo_texture = SHORTS_TEX

func color_toon() -> void:
	var meshes : Array[MeshInstance3D] = []
	for child in toon.body.skeleton.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
	for child in get_all_children(toon.head):
		if child is MeshInstance3D:
			meshes.append(child)
	
	for mesh in meshes:
		for i in mesh.mesh.get_surface_count():
			if not mesh.get_surface_override_material(i):
				mesh.set_surface_override_material(i, mesh.mesh.surface_get_material(i).duplicate())
			stonify(mesh.get_surface_override_material(i))

func get_all_children(node : Node) -> Array[Node]:
	var nodes : Array[Node] = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

func stonify(material : StandardMaterial3D) -> void:
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = false
	material.next_pass = material.duplicate()
	material.next_pass.albedo_texture = STONE_TEX
	material.next_pass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.next_pass.albedo_color = Color(0.5, 0.5, 0.5, 0.75)

func pose_toon() -> void:
	toon.set_animation(POSE_ANIMS[pose])
	toon.animator.seek(POSE_TIMES[pose], true)
	toon.animator.pause()

@export var test : Color
