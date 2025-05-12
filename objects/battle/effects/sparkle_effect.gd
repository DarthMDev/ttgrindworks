@tool
extends GPUParticles3D
class_name SparkleEffect

@export var center_color : Color:
	set(x):
		center_color = x
		refresh_mesh()
@export var edge_color : Color:
	set(x):
		edge_color = x
		refresh_mesh()


func _ready() -> void:
	refresh_mesh()

func refresh_mesh() -> void:
	draw_pass_1 = generate_mesh()

func generate_mesh() -> Mesh:
	var tmpMesh := ArrayMesh.new()
	var vertices : PackedVector3Array = []
	var uvs : PackedVector2Array = []
	
	vertices.push_back(position)
	vertices.push_back(position + Vector3(1.0, 0.0, 0.0))
	vertices.push_back(position)
	vertices.push_back(position + Vector3(-1.0, 0.0, 0.0))
	vertices.push_back(position)
	vertices.push_back(position+Vector3(0.0, 1.0, 0.0))
	vertices.push_back(position)
	vertices.push_back(position+Vector3(0.0, -1.0, 0.0))
	vertices.push_back(position)
	vertices.push_back(position+Vector3(0.0, 0.0, 1.0))
	vertices.push_back(position)
	vertices.push_back(position+Vector3(0.0, 0.0, -1.0))
	
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(1, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(1, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(1, 0))
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	st.set_material(mat)
	
	for v in vertices.size(): 
		if v % 2 == 0:
			st.set_color(center_color)
		else:
			st.set_color(edge_color)
		st.set_uv(uvs[v])
		st.add_vertex(vertices[v])
	
	st.commit(tmpMesh)
	
	return tmpMesh
