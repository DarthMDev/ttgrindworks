extends Node3D
class_name ToonLegs

enum ShoeType {
	NONE,
	SHOE,
	SHORT_BOOT,
	LONG_BOOT,
}


@export var anim: String
@export var animator: AnimationPlayer
@export var skeleton: Skeleton3D

@export var legs: MeshInstance3D
@export var feet: MeshInstance3D
@export var boots_short: MeshInstance3D
@export var boots_long: MeshInstance3D
@export var shoes: MeshInstance3D
@export var hip_bone: BoneAttachment3D
@export var shadow_bone: BoneAttachment3D


func set_animation(animation: String, custom_blend := -1, custom_speed := 1.0, from_end := false):
	if animator.has_animation(animation):
		skeleton.reset_bone_poses()
		animator.play(animation, custom_blend, custom_speed, from_end)
		animator.advance(0.0)
	else:
		push_warning("Invalid toon animation: %s" % animation)
	anim = animator.current_animation

func set_shoes(shoe_type: ShoeType, texture: Texture2D = null) -> void:
	var mesh: MeshInstance3D = feet
	match shoe_type:
		ShoeType.SHOE: mesh = shoes
		ShoeType.SHORT_BOOT: mesh = boots_short
		ShoeType.LONG_BOOT: mesh = boots_long
	for m in [shoes, boots_short, boots_long, feet]:
		m.set_visible(m == mesh)
	
	if mesh == feet: return
	else:
		var mat: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate(true)
		mat.albedo_texture = texture
		mesh.set_surface_override_material(0, mat)
	
