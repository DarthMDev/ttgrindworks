extends Node

## Used for UI. Only applies to items with "remember_item" true
signal s_item_applied(item: Item)

var seen_items: Array[Item] = []
# Items currently available for collection in any way
var items_in_play: Array[Item] = []

## Certain items cannot be seen if the other has been seen on this run.
var linked_items: Array = [
	# Gag pack and goggles binding
	[
		load("res://objects/items/resources/accessories/backpacks/gag_pack.tres"),
		load("res://objects/items/resources/accessories/glasses/goggles.tres"),
	]
]

const POOL_PATHS: Array[String] = [
	"res://objects/items/pools/accessories.tres",
	"res://objects/items/pools/active_items.tres",
	"res://objects/items/pools/battle_clears.tres",
	"res://objects/items/pools/candies.tres",
	"res://objects/items/pools/doodle_treasure.tres",
	"res://objects/items/pools/everything.tres",
	"res://objects/items/pools/floor_clears.tres",
	"res://objects/items/pools/item_roll_fails.tres",
	"res://objects/items/pools/jellybeans.tres",
	"res://objects/items/pools/progressives.tres",
	"res://objects/items/pools/rewards.tres",
	"res://objects/items/pools/shop_progressives.tres",
	"res://objects/items/pools/shop_rewards.tres",
	"res://objects/items/pools/special_items.tres",
	"res://objects/items/pools/super_candies.tres",
	"res://objects/items/pools/toontasks.tres",
	"res://objects/items/pools/treasures.tres",
]

var POOLS: Dictionary[String, ItemPool] = {}




func _init():
	# Assign our item pools
	for path in POOL_PATHS:
		create_centralized_pool(path)

func _ready() -> void:
	# Clear out temp seen items upon every floor start
	Util.s_floor_ended.connect(on_floor_end)
	SaveFileService.s_reset.connect(reset)

func reset() -> void:
	seen_items.clear()
	items_in_play.clear()

func get_random_item(pool: ItemPool, override_rolls := false) -> Item:
	## Rolls to force progression items when they're needed:
	if not override_rolls:
		# Gag roll
		var gag_roll := RandomService.randf_channel("gag_rolls")
		print('Gag rate is ' + str(get_gag_rate()) + ' Gag roll is ' + str(gag_roll))
		if gag_roll < get_gag_rate():
			print('Forcing gag spawn')
			return load('res://objects/items/resources/passive/track_frame.tres').duplicate()
		# Laff roll
		var laff_roll := RandomService.randf_channel("laff_rolls")
		print('Laff rate is %f, and Laff roll is %f' % [get_laff_rate(), laff_roll])
		if laff_roll < get_laff_rate():
			print('Forcing laff spawn')
			return load('res://objects/items/resources/passive/laff_boost.tres').duplicate()
		#var bean_roll := RandomService.randf_channel("bean_rolls")
		#print('Bean rate is %f and bean roll is %f' % [get_bean_rate(), bean_roll])
		#if bean_roll < get_bean_rate():
			#print('Forcing bean spawn')
			#return get_random_item(BEAN_POOL, true)
	
	# Get the centralized version of the pool
	pool = get_centralized_pool(pool)
	
	# 50% chance to remove all active items from the pool
	var exclude_actives := not override_rolls and RandomService.randi_channel('active_item_discard') % 2 == 0
	
	# Our base rarity goal for this roll
	var rarity_goal: int = 0
	var lowest_rarity := pool.get_lowest_rarity()
	if rarity_goal < lowest_rarity:
		rarity_goal = lowest_rarity
	if not pool.low_roll_override == Item.Rarity.NIL:
		rarity_goal = pool.low_roll_override as int
	
	# Trim out all seen items from pool
	var trimmed_pool: Array[Item] = []
	for item in pool.items:
		if item is ItemActive and exclude_actives:
			continue
		if not flag_check(item):
			continue
		if not item in seen_items:
			trimmed_pool.append(item)
	
	# If no item can be given to the player, just give them treasure
	if trimmed_pool.size() == 0:
		return get_random_roll_fail_item()
	
	# Quality-scaled rarity
	var quality_trimmed_pool: Array[Item] = []
	# Rarity goal determines what item rarities we want to allow into the pool.
	# Once the rarity goal is determined, any item up to and including that rarity can be drawn.
	# Include Q1: 100%
	# Include Q2: 85%
	# Include Q3: 72.3%
	# Include Q4: 61.4%
	# Include Q5: 52.2%
	# Include Q6: 44.3%
	# Include Q7: 37.7%
	# If a low rarity is drawn that has no items available, there is a continuous 50% chance to upgrade to the next rarity.
	# If this fails, a random treasure will be given to the player instead.
	while RandomService.randi_channel('item_quality_roll') % 100 < 85 and rarity_goal < Item.Rarity.values().max():
		rarity_goal += 1

	var is_first_roll := true
	while quality_trimmed_pool.is_empty() and (is_first_roll or RandomService.randf_channel('item_quality_roll') < 0.5) and rarity_goal <= Item.Rarity.values().max():
		if is_first_roll:
			is_first_roll = false
		else:
			rarity_goal += 1

		for item: Item in trimmed_pool:
			var rarity: Item.Rarity = item.rarity
			if rarity == Item.Rarity.NIL:
				rarity = Item.QualityToRarity[item.qualitoon]
			if Item.RarityToRolls[rarity] <= rarity_goal:
				quality_trimmed_pool.append(item)

	# If STILL no item can be given to the player, just give them treasure
	if quality_trimmed_pool.is_empty():
		print("Empty quality-trimmed pool. Spawning fallback.")
		return get_random_roll_fail_item()
	
	var file_name := pool.resource_path.get_file()
	var res_name := file_name.trim_suffix(".%s" % file_name.get_extension())
	return RandomService.array_pick_random(res_name, quality_trimmed_pool)

func get_random_roll_fail_item() -> Item:
	return get_random_item(load("res://objects/items/pools/item_roll_fails.tres"), true)

func seen_item(item: Item, allow_duplicate := false):
	if not allow_duplicate and item.resource_path == "":
		return
	
	if not item in seen_items:
		seen_items.append(item)
		var _linked_items: Array[Item] = get_linked_items(item)
		if _linked_items:
			for _li: Item in _linked_items:
				if not _li in seen_items:
					print("Adding linked seen item: %s" % _li.item_name)
					seen_items.append(item)

# For reactions/descriptions
var items_in_proximity: Array[WorldItem]

func item_in_proximity(item: WorldItem):
	if items_in_proximity.find(item) == -1:
		items_in_proximity.append(item)

func item_left_proximity(item: WorldItem):
	var place := items_in_proximity.find(item)
	if place != -1:
		items_in_proximity.remove_at(place)

func apply_inventory() -> void:
	var player := Util.get_player()
	var items: Array[Item] = player.stats.items
	var hat: ItemAccessory
	var glasses: ItemAccessory
	var backpack: ItemAccessory
	
	# Iterate through items to find accessories
	# As well as any special items
	# Setting values like this ensures only the newest items are applied
	for item in items:
		match item.slot:
			Item.ItemSlot.HAT:
				hat = item
			Item.ItemSlot.GLASSES:
				glasses = item
			Item.ItemSlot.BACKPACK:
				backpack = item
		for value in item.player_values.keys():
			player.set(value, item.player_values[value])
	
		# If a script item is found, run the load method
		if item.item_script:
			var item_node := ItemScript.add_item_script(Util.get_player(), item.item_script)
			if item_node is ItemScript:
				item_node.on_load(item)
	
	# Place accessory items on player
	var accessories: Array[ItemAccessory] = [hat, glasses, backpack]
	for accessory in accessories:
		if not accessory:
			continue
		var bone : BoneAttachment3D
		match accessory.slot:
			Item.ItemSlot.HAT:
				bone = player.toon.hat_bone
			Item.ItemSlot.GLASSES:
				bone = player.toon.glasses_bone
			Item.ItemSlot.BACKPACK:
				bone = player.toon.backpack_bone
		if not bone:
			continue
		var model: Node3D = accessory.model.instantiate()
		bone.add_child(model)
		var accessory_placement : AccessoryPlacement = ItemAccessory.get_placement(accessory,Util.get_player().character.dna)
		if not accessory_placement:
			model.queue_free()
			push_warning(accessory.item_name + " has no placement specified for this Toon's DNA!")
			continue
		model.position = accessory_placement.position
		model.rotation_degrees = accessory_placement.rotation
		model.scale = accessory_placement.scale


const GagGoals: Dictionary = {
	1: 0.2,
	2: 0.375,
	3: 0.55,
	4: 0.725,
	5: 0.9,
	6: 1.0,
}

func get_gag_rate() -> float:
	if not Util.get_player():
		return 0
	
	var floor_num := maxi(Util.floor_number + 1, 1)
	
	var stats := Util.get_player().stats
	var total_gags := 0
	var collected_gags := 0
	
	# Find the base amount of gags the player has
	for key in stats.gags_unlocked.keys():
		for track: Track in stats.character.gag_loadout.loadout:
			if track.track_name == key:
				total_gags += track.gags.size()
		collected_gags += stats.gags_unlocked[key]
	
	# Now, find the track frames currently in play and add those to the total
	for item: Item in items_in_play:
		if item.arbitrary_data.has('track'):
			collected_gags += 1
	
	# Don't allow track frames to spawn when all gags have been acquired
	if collected_gags >= total_gags:
		return 0.0
	
	var gag_percent: float = float(collected_gags) / float(total_gags)
	# We aim for the player to have collected all of their gags by the end of Floor 5. (Considered floor 6 by this code)
	# Floor 0: 20% of all gags collected
	# Floor 1: 35% of all gags collected
	# Floor 2: 50% of all gags collected
	# Floor 3: 70% of all gags collected
	# Floor 4: 90% of all gags collected
	# Floor 5: 100% of all gags collected
	var goal_percent := minf(GagGoals[floor_num], 1.0)
	
	var chance := (1.0 - (gag_percent / goal_percent)) * 1.35
	
	return chance

const STARTING_LAFF := 30
const FLOOR_LAFF_INCREMENT := 14
const LIKELIHOOD_PER_POINT := 0.1
func get_laff_rate() -> float:
	if not is_instance_valid(Util.get_player()):
		return 0.0
	
	# Get the current laff total
	# Take player's max hp + all the other laff boost items in play
	var laff_total := Util.get_player().stats.max_hp
	for laff_boost : Item in get_items_in_play("Laff Boost"):
		if laff_boost.stats_add.has('max_hp'):
			laff_total += laff_boost.stats_add['max_hp']
	
	# Get the laff goal
	var laff_goal := STARTING_LAFF + (FLOOR_LAFF_INCREMENT * Util.floor_number + 1)
	
	var goal_diff : = laff_goal - laff_total
	
	var laff_rate := clampf(goal_diff * LIKELIHOOD_PER_POINT, 0.0, 0.5)
	
	return laff_rate

const BEAN_GOAL := 30
const LIKELIHOOD_PER_BEAN := 0.05
func get_bean_rate() -> float:
	if not is_instance_valid(Util.get_player()):
		return 0.0
	
	var bean_total := Util.get_player().stats.money
	
	for item: Item in items_in_play:
		if item.stats_add.has('money'):
			bean_total += item.stats_add['money']
	
	var goal_diff := BEAN_GOAL - bean_total
	
	var bean_rate := clampf(goal_diff * LIKELIHOOD_PER_BEAN, 0.0, 0.25)
	
	return bean_rate

func on_floor_end() -> void:
	return

func item_created(item: Item) -> void:
	items_in_play.append(item)

func item_removed(item: Item) -> void:
	items_in_play.erase(item)

func get_closest_item() -> WorldItem:
	var dist := -1.0
	var item : WorldItem
	for itm in items_in_proximity:
		var dist2 := absf(itm.global_position.distance_to(Util.get_player().global_position))
		if dist2 < dist or dist < 0.0:
			dist = dist2
			item = itm
	return item

func get_items_in_play(item_name: String) -> Array[Item]:
	var return_array: Array[Item] = []
	for item: Item in items_in_play:
		if item.item_name == item_name:
			return_array.append(item)
	return return_array

func get_linked_items(item: Item) -> Array[Item]:
	var final_linked_items: Array[Item] = []
	for _ll: Array in linked_items:
		if item in _ll:
			final_linked_items.assign(_ll.filter(func(x: Item): return x != item))
			return final_linked_items

	return final_linked_items

func flag_check(item : Item) -> bool:
	
	return true

const ITEM_GET_UI := "res://objects/items/ui/item_get_ui/item_get_ui.tscn"
func display_item(item : Item) -> Control:
	var ui : Control = load(ITEM_GET_UI).instantiate()
	ui.item = item
	get_tree().get_root().add_child(ui)
	return ui

## Attempts to return the centralized version of the item pool
## If none exists, just returns the pool given
func get_centralized_pool(pool: ItemPool) -> ItemPool:
	var path := pool.resource_path
	if path in POOLS.keys():
		return POOLS[path]
	return pool

## If a centralized item pool exists, it will return that
## Otherwise, it will make a new centralized pool and return that
func pool_from_path(path: String) -> ItemPool:
	if path in POOLS.keys():
		return POOLS[path]
	else:
		return create_centralized_pool(path)

func create_centralized_pool(path: String) -> ItemPool:
	var new_pool: ItemPool = load(path)
	POOLS[path] = new_pool
	return new_pool


#region Pool Pointers
var BEAN_POOL: ItemPool:
	get: return pool_from_path("res://objects/items/pools/jellybeans.tres")
var REWARD_POOL: ItemPool:
	get: return pool_from_path("res://objects/items/pools/rewards.tres")
var PROGRESSIVE_POOL: ItemPool:
	get: return pool_from_path("res://objects/items/pools/progressives.tres")


#endregion
