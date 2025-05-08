extends ItemScriptActive

const DISTANCE_LIMIT := 3.0
const CHEST = "res://objects/interactables/treasure_chest/treasure_chest.tscn"


func use() -> void:
	var player = Util.get_player()
	
	var dist := -1.0
	var closest_chest: TreasureChest
	var chests := search_node(SceneLoader)
	
	for chest in chests:
		var test_dist : float = player.global_position.distance_to(chest.global_position)
		if dist < 0 or test_dist < dist:
			closest_chest = chest
			dist = test_dist
	
	if not closest_chest or dist > DISTANCE_LIMIT:
		cancel_use()
		return
	
	var chest : TreasureChest = load(CHEST).instantiate()
	chest.override_replacement_rolls = true
	chest.item_pool = closest_chest.item_pool
	chest.override_item = closest_chest.override_item
	closest_chest.get_parent().add_child(chest)
	chest.update_texture(closest_chest.get_current_texture())
	chest.set_ray_gradient(closest_chest.ray_tex.gradient)
	
	# Positions the chest between the player and chest
	chest.global_position = closest_chest.global_position
	chest.scale = closest_chest.scale
	var dir_to = chest.global_position.direction_to(player.global_position)
	dir_to *= dist / 2
	chest.global_position += Vector3(dir_to.x, 0, dir_to.z)
	
	# Rotates the chest to look at the player
	chest.look_at(player.global_position)
	chest.rotation = Vector3(0, chest.rotation.y + deg_to_rad(180), 0)
	
	# Poof effect
	var dust_cloud = Globals.DUST_CLOUD.instantiate()
	chest.get_parent().add_child(dust_cloud)
	dust_cloud.scale *= chest.scale
	dust_cloud.global_position = chest.global_position

func search_node(node : Node) -> Array[TreasureChest]:
	var chests : Array[TreasureChest] = []
	for child in node.get_children():
		if child is TreasureChest:
			if child.opened and len(child.get_node("Item").get_children()) == 0:
				continue
			chests.append(child)
		else:
			chests.append_array(search_node(child))
	return chests
