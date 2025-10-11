extends Node3D

func _ready() -> void:
	var world_item: WorldItem = NodeGlobals.get_ancestor_of_type(self, WorldItem)
	if is_instance_valid(world_item):
		world_item.queue_free()
