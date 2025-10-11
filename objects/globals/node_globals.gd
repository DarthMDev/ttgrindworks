extends Object
class_name NodeGlobals

static func calculate_spatial_bounds(
	parent: Node3D, 
	exclude_top_level_transform: bool,
	exclude_children: Array[Node3D] = []
) -> AABB:
	var bounds: AABB = AABB()
	if parent is VisualInstance3D:
		bounds = parent.get_aabb();

	for i in range(parent.get_child_count()):
		if not parent.get_child(i) is Node3D: continue
		var child: Node3D = parent.get_child(i)
		if child and child not in exclude_children:
			var child_bounds: AABB = calculate_spatial_bounds(child, false, exclude_children)
			if bounds.size == Vector3.ZERO and parent:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)
	if bounds.size == Vector3.ZERO and not parent:
		bounds = AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))
	if not exclude_top_level_transform:
		bounds = parent.transform * bounds
	return bounds

## Awaits a node being ready or instantly returns if it is already ready.
static func until_ready(node: Node) -> void:
	if not node.is_node_ready():
		await node.ready

## Gets the first child of a node of the given type.
static func get_child_of_type(node: Node, type) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
	return null

## Gets all children of a node of the given type.
static func get_children_of_type(node: Node, type, recursive := false) -> Array[Node]:
	var children: Array[Node] = []
	for child in node.get_children():
		if is_instance_of(child, type):
			children.append(child)
		if recursive:
			children.append_array(get_children_of_type(child, type, true))
	return children

## Continues looking upwards until finding an ancestor of the given type.
static func get_ancestor_of_type(node: Node, type: GDScript) -> Node:
	node = node.get_parent()
	while not is_instance_of(node, type):
		node = node.get_parent()
		if not node:
			break
	return node
