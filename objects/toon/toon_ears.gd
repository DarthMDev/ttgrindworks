extends Node3D
class_name ToonEars

@export var anim: String
@export var animator: AnimationPlayer
@export var skeleton: Skeleton3D
@export var ears: MeshInstance3D


func set_animation(animation: String, custom_blend := -1, custom_speed := 1.0, from_end := false):
	if animator.has_animation(animation):
		skeleton.reset_bone_poses()
		animator.play(animation, custom_blend, custom_speed, from_end)
		animator.advance(0.0)
	else:
		push_warning("Invalid toon animation: %s" % animation)
	anim = animator.current_animation
