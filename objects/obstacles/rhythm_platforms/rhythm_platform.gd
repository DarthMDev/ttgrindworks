extends MeshInstance3D
class_name RhythmPlatform

const DISABLED_ALPHA := 0.25

@export var base_material : StandardMaterial3D
@export var platform_group := 0
@export var collision_body : CollisionObject3D

var material : StandardMaterial3D
var enabled := true

signal s_enabled_set(enable : bool)


func _ready() -> void:
	material = base_material.duplicate(true)
	set_surface_override_material(0,material)

func set_color(color : Color) -> void:
	material.albedo_color = color

func set_enabled(enable : bool) -> void:
	match enable:
		true:
			if collision_body : collision_body.set_collision_layer_value(1, true)
			material.albedo_color.a = 1.0
		false:
			if collision_body : collision_body.set_collision_layer_value(1, false)
			material.albedo_color.a = DISABLED_ALPHA
	
	s_enabled_set.emit(enabled)
