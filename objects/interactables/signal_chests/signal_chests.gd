extends Node3D


func spawn_chests() -> void:
	for child in get_children():
		var chest := Globals.TREASURE_CHEST.instantiate()
		child.add_child(chest)
		chest.add_child(Globals.DUST_CLOUD.instantiate())
