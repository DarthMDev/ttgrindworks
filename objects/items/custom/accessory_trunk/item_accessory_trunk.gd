extends ItemScriptActive

const WORLD_ITEM = preload("res://objects/items/world_item/world_item.tscn")
const ACC_POOL = preload("res://objects/items/pools/accessories.tres")

func use() -> void:
	var acc_pool = ACC_POOL.duplicate()
	acc_pool.low_roll_override = Item.Rarity.Q7
	
	# Makes this work in debug rooms
	var zone
	if is_instance_valid(Util.floor_manager):
		zone = Util.floor_manager.get_current_room()
	else:
		zone = SceneLoader
	
	# OoOoooOooO look away from position calculations oOoOoOoo
	var rel_basis = Util.get_player().toon.global_basis
	var rel_pos = Util.get_player().global_position + (rel_basis * Vector3(0, .2, 3))
	var raycast_check = Util.get_player().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Util.get_player().global_position, rel_pos, 0b0001))
	if raycast_check:
		rel_pos = raycast_check.position - (rel_basis * Vector3(0,0,.5))
	
	var item_count = RandomService.randi_range_channel('accessory_trunk_items', 2, 4)
	var offset_amount = 2.5
	if item_count % 2 != 0:
		offset_amount = 2
	var side_dist = rel_basis * Vector3(item_count / offset_amount, 0, 0)
	rel_pos += side_dist
	
	var right_side_raycast = Util.get_player().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(rel_pos, rel_pos - (side_dist * 2), 0b0001))
	var left_side_raycast = Util.get_player().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(rel_pos - side_dist, rel_pos, 0b0001))
	if right_side_raycast:
		var dist = rel_pos.distance_to(right_side_raycast.position)
		rel_pos += (rel_basis * Vector3((item_count - dist), 0, 0))
	if left_side_raycast:
		rel_pos = left_side_raycast.position - (rel_basis * Vector3(.5, 0, 0))
	
	for i in item_count:
		var item = WORLD_ITEM.instantiate()
		item.override_replacement_rolls = true
		item.pool = acc_pool
		zone.add_child(item)
		item.global_position = rel_pos + (rel_basis * Vector3(-1 * i, 0.25, 0))
		var dust_cloud = Globals.DUST_CLOUD.instantiate()
		zone.add_child(dust_cloud)
		dust_cloud.scale *= item.scale
		dust_cloud.global_position = item.global_position
		await Task.delay(0.1)

	attempt_disconnect()
	Util.get_player().stats.current_active_item = null
