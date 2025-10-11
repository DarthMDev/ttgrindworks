extends Node3D

var base_scale := 0.46

@onready var start := $SprayStart
@onready var end := $SprayEnd
@onready var spray1 : MeshInstance3D = $SprayStart/Spray
@onready var spray2 : MeshInstance3D = $SprayEnd/Spray

var spray_mat : StandardMaterial3D

func _ready() -> void:
	spray_mat = spray1.mesh.surface_get_material(0).duplicate(true)
	spray1.set_surface_override_material(0, spray_mat)
	spray2.set_surface_override_material(0, spray_mat)

func spray(pos : Vector3,spray_time : float) -> void:
	look_at(pos)
	
	var dist := global_position.distance_to(pos)
	var target_scale := 5.0*global_basis.get_scale().z*dist*base_scale
	end.scale.z = target_scale
	end.global_position = pos
	
	# Create tween
	var spray_tween := create_tween()
	spray_tween.tween_property(start,'scale:z',target_scale,0.333)
	spray_tween.tween_interval(spray_time)
	spray_tween.tween_callback(start.set_visible.bind(false))
	spray_tween.tween_callback(end.set_visible.bind(true))
	spray_tween.tween_property(end,'scale:z',0.0,0.333)
	
	await spray_tween.finished
	spray_tween.kill()
	hide()

func set_color(color : Color) -> void:
	spray_mat.albedo_color = color
