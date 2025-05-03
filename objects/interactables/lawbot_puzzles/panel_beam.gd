@tool
extends MeshInstance3D
class_name PanelBeam


## Locals
var connected_panel : PuzzlePanel

## Connect a panel to the beam
func connect_panel(panel : PuzzlePanel) -> void:
	connected_panel = panel
	panel.s_shape_changed.connect(generate_mesh)
	panel.s_color_changed.connect(update_color)

## Get the current shape of the panel
func get_panel_shape() -> GeneratedMesh:
	if not connected_panel:
		return null
	return connected_panel.panel_shapes[connected_panel.panel_shape]

## Get the current color of the panel
func get_panel_color() -> Color:
	if not connected_panel or connected_panel.mesh.get_surface_count() == 0 or not connected_panel.mesh.surface_get_material(0):
		return Color.WHITE
	return connected_panel.mesh.surface_get_material(0).albedo_color

## Get the relative position to the point on the shape
func get_relative_position(point : Vector3) -> Vector3:
	var pos_diff := connected_panel.position-position
	pos_diff+=point
	return pos_diff

## Generates the beam mesh
func generate_mesh(_panel,_shape) -> void:
	# Generate a new mesh based on the outline of the panel's mesh
	var new_mesh := GeneratedMesh.new()
	new_mesh.primitive_type = Mesh.PRIMITIVE_TRIANGLE_STRIP
	for point in get_panel_shape().vertices:
		new_mesh.vertices.append(Vector3(0,0,0))
		new_mesh.vertices.append(get_relative_position(point))
	if not new_mesh.vertices.is_empty():
		new_mesh.vertices.append(Vector3(0,0,0))
	mesh = new_mesh.to_mesh()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = get_panel_color()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if not mesh.get_surface_count() == 0:
		mesh.surface_set_material(0,mat)
		update_color(get_panel_color())

func update_color(new_color : Color) -> void:
	if mesh and mesh.get_surface_count() > 0 and mesh.surface_get_material(0):
		mesh.surface_get_material(0).albedo_color = new_color
		if new_color == Color.WHITE:
			update_alpha(0.002)
		else:
			update_alpha(new_color.a / 200.0)

func update_alpha(alpha : float) -> void:
	mesh.surface_get_material(0).albedo_color.a = alpha
