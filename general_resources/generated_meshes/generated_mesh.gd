@tool
extends Resource
class_name GeneratedMesh

@export var vertices : PackedVector3Array
@export var primitive_type : Mesh.PrimitiveType


func to_mesh() -> Mesh:
	var tmpMesh = ArrayMesh.new()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	
	var st = SurfaceTool.new()
	st.begin(primitive_type)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	
	for v in vertices.size(): 
		st.set_color(Color.WHITE)
		st.add_vertex(vertices[v])
		
	st.commit(tmpMesh)
	
	return tmpMesh
