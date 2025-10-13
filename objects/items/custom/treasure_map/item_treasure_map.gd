extends ItemScriptActive

const DISTANCE_LIMIT := 3.0
const CHEST = "res://objects/interactables/treasure_chest/treasure_chest.tscn"


func validate_use() -> bool:
	return is_instance_valid(find_chest())

func use() -> void:
	var closest_chest := find_chest()
	closest_chest.make_duplicate_chest()

func search_node(node: Node) -> Array[TreasureChest]:
	var chests: Array[TreasureChest] = []
	for child in node.get_children():
		if child is TreasureChest:
			if child.opened:
				continue
			chests.append(child)
		else:
			chests.append_array(search_node(child))
	return chests

func get_zone() -> Node:
	if is_instance_valid(Util.floor_manager):
		return Util.floor_manager.get_current_room()
	return SceneLoader.current_scene

func find_chest() -> TreasureChest:
	var chests := search_node(get_zone())
	var player := Util.get_player()
	var dist := -1.0
	var closest_chest: TreasureChest
	for chest in chests:
		var test_dist: float = player.global_position.distance_to(chest.global_position)
		if dist < 0 or test_dist < dist:
			closest_chest = chest
			dist = test_dist
	if dist > DISTANCE_LIMIT: return null
	
	return closest_chest
