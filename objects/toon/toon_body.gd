extends Node3D
class_name ToonBody


@export var anim: String
@export var animator: AnimationPlayer
@export var skeleton: Skeleton3D

@export_category("Bones")
# Accessory bones
@export var hat_bone: BoneAttachment3D
@export var glasses_bone: BoneAttachment3D
@export var backpack_bone: BoneAttachment3D
@export var head_bone: BoneAttachment3D

# Battle Necessary Bones
@export var right_hand_bone: BoneAttachment3D
@export var left_hand_bone: BoneAttachment3D
@export var flower_bone: BoneAttachment3D



@export_category("Meshes")
@export var shirt: MeshInstance3D
@export var bottoms: MeshInstance3D
@export var neck: MeshInstance3D
@export var arms: MeshInstance3D
@export var sleeves: MeshInstance3D
@export var hands: MeshInstance3D


func set_animation(animation: String, custom_blend := -1, custom_speed := 1.0, from_end := false):
	if animator.has_animation(animation):
		skeleton.reset_bone_poses()
		animator.play(animation, custom_blend, custom_speed, from_end)
		animator.advance(0.0)
	else:
		push_warning("Invalid toon animation: %s" % animation)
	anim = animator.current_animation
