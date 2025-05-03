@tool
extends MeshInstance3D
class_name PuzzlePanel

enum PanelShape {
	NOTHING,
	SQUARE,
	SKULL,
	DOT,
	TRIANGLE,
	X,
	DIAMOND,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	QUESTIONMARK,
	BIGSQUARE,
}
@export var panel_shape := PanelShape.NOTHING:
	set(x):
		panel_shape = x
		mesh = panel_shapes[panel_shape].to_mesh()
		if not x == PanelShape.NOTHING:
			mesh.surface_get_material(0).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s_shape_changed.emit(self, x)

## Locals
var panel_shapes := {
	PanelShape.NOTHING : GeneratedMesh.new(),
	PanelShape.SQUARE : preload('res://general_resources/generated_meshes/puzzle_square.tres'),
	PanelShape.SKULL : preload('res://general_resources/generated_meshes/puzzle_skull.tres'),
	PanelShape.DOT : preload("res://general_resources/generated_meshes/puzzle_dot.tres"),
	PanelShape.TRIANGLE : preload("res://general_resources/generated_meshes/puzzle_triangle.tres"),
	PanelShape.X : preload("res://general_resources/generated_meshes/puzzle_x.tres"),
	PanelShape.DIAMOND : preload("res://general_resources/generated_meshes/puzzle_diamond.tres"),
	PanelShape.ONE : preload("res://general_resources/generated_meshes/puzzle_one.tres"),
	PanelShape.TWO : preload("res://general_resources/generated_meshes/puzzle_two.tres"),
	PanelShape.THREE : preload("res://general_resources/generated_meshes/puzzle_three.tres"),
	PanelShape.FOUR : preload("res://general_resources/generated_meshes/puzzle_four.tres"),
	PanelShape.FIVE : preload("res://general_resources/generated_meshes/puzzle_five.tres"),
	PanelShape.SIX : preload("res://general_resources/generated_meshes/puzzle_six.tres"),
	PanelShape.QUESTIONMARK : preload("res://general_resources/generated_meshes/puzzle_question_mark.tres"),
	PanelShape.BIGSQUARE : preload("res://general_resources/generated_meshes/puzzle_big_square.tres")
}
var area : Area3D
var pos : Vector2i
var collision_box : BoxShape3D
var select_mesh : MeshInstance3D

# Signals
signal s_player_entered(panel : PuzzlePanel)
signal s_player_exited(panel : PuzzlePanel)
signal s_shape_changed(panel : PuzzlePanel, shape : PanelShape)
signal s_color_changed(color : Color)

func _ready() -> void:
	# Prepare collision
	area = Area3D.new()
	add_child(area)
	area.collision_mask = Globals.PLAYER_COLLISION_LAYER
	var collision_shape := CollisionShape3D.new()
	area.add_child(collision_shape)
	area.position = Vector3(.5,0,.5)
	collision_shape.set_shape(BoxShape3D.new())
	collision_box = collision_shape.shape
	collision_box.size*=.72
	collision_box.size.y=100.0
	area.body_entered.connect(body_entered)
	area.body_exited.connect(body_exited)
	
	# Prepare selection mesh
	select_mesh = MeshInstance3D.new()
	add_child(select_mesh)
	select_mesh.mesh = panel_shapes[PanelShape.BIGSQUARE].to_mesh()
	select_mesh.mesh.surface_get_material(0).albedo_color = Color.RED
	select_mesh.hide()

func set_alpha(alpha : float) -> void:
	if panel_shape != PanelShape.NOTHING:
		mesh.surface_get_material(0).albedo_color.a = alpha
		s_color_changed.emit(mesh.surface_get_material(0).albedo_color)

func get_alpha() -> float:
	if panel_shape == PanelShape.NOTHING:
		return 0.0
	return mesh.surface_get_material(0).albedo_color.a

func body_entered(body) -> void:
	if body is Player:
		s_player_entered.emit(self)
		select_mesh.show()

func body_exited(body) -> void:
	if body is Player:
		s_player_exited.emit(self)
		select_mesh.hide()

func set_color(color : Color) -> void:
	if panel_shape != PanelShape.NOTHING:
		mesh.surface_get_material(0).albedo_color = color
		s_color_changed.emit(color)

var fade_tween : Tween
func fade(strength : float, time : float) -> Tween:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_method(set_alpha, get_alpha(), strength, 0.0)
	fade_tween.tween_method(set_alpha, strength, 0.0, time)
	fade_tween.finished.connect(fade_tween.kill)
	return fade_tween


func custom_fade(strength : float, time : float) -> Tween:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_method(set_alpha, get_alpha(), strength, time)
	fade_tween.finished.connect(fade_tween.kill)
	return fade_tween
