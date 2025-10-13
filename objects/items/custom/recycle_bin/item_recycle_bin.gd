extends ItemScriptActive

const BOOST_STATS: Array[String] = ['damage', 'defense', 'evasiveness', 'speed']
const BOOST_PER_STAR := 0.04

func validate_use() -> bool:
	return is_instance_valid(find_item())

func use() -> void:
	sell_item(find_item())

func can_sell_item(world_item: WorldItem) -> bool:
	if not world_item.monitoring: return false
	elif world_item.get_node_or_null('CollisionShape3D') == null: return false
	
	return true

func sell_item(world_item: WorldItem) -> void:
	var player := Util.get_player()
	var boosts := (world_item.item.qualitoon as int) + 1
	for i in boosts:
		boost_random_stat(player)
	world_item.destroy_item()

func boost_random_stat(player: Player) -> void:
	var stats := player.stats
	var boost_stat: String = RNG.channel(RNG.ChannelRecycleBinStats).pick_random(BOOST_STATS)
	stats.set(boost_stat, stats.get(boost_stat) + BOOST_PER_STAR)

func find_item() -> WorldItem:
	var world_item := ItemService.get_closest_item()
	if not world_item or not can_sell_item(world_item):
		return
	return world_item
