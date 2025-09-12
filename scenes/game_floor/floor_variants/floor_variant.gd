extends Resource
class_name FloorVariant

## Default Item Pool
var FALLBACK_REWARD_POOL: ItemPool
## Default Cog Pool
var FALLBACK_COG_POOL: CogPool
## Amount of rooms to add per difficulty (includes connectors)
static var DIFFICULTY_ROOM_ADDITION := 2

static var ANOMALIES_POSITIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overheal.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_record_profits.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_organic_gags.gd",
	#"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_down.gd",
	#"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_inspiration.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_victory_cry.gd",
]
static var ANOMALIES_NEUTRAL: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_reorganization.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_volatile_market.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_mixed_bag.gd",
	#"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_status_report.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_stagnant_air.gd"
]
static var ANOMALIES_NEGATIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_bull_market.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_cog_damage_up.gd",
	#"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_out_of_touch.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_safety_violations.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_time_crunch.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_inflation.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_double_trouble.gd",
]
static var ANOMALIES_NEGATIVE_TRUE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_bull_market.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_cog_damage_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_time_crunch.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_double_trouble.gd",
]

static var LEVEL_RANGES: Dictionary[int, Array] = {
	0: [1, 2],
	1: [4, 5],
	2: [6, 7],
	3: [8, 9],
	4: [11, 12],
	5: [13, 15],
	6: [21, 22], #shouldn't happen but just incase / testing
	7: [20, 21],
	8: [21, 22],
	9: [23, 24],
}

## Floor difficulty from 0-5
@export_range(0, 5) var floor_difficulty := 0

## The department floor resource to pull rooms from
@export var floor_type: DepartmentFloor

## The name to display upon spawning in
@export var floor_name := "Facility"

## Item is granted upon floor completion
@export var reward_pool: ItemPool

## Cog pool to use for the floor
@export var cog_pool: CogPool

## If this floor variant should take you to a scene other than game floor.
@export var override_scene: PackedScene

## Floor modification scripts to run
@export var modifiers: Array[Script]

## Optional. For if a floor variant should have a different boss set than usual.
@export var end_rooms: Array[FacilityRoom]

## Alternative version of the floor
@export var alt_floor: FloorVariant

@export var floor_icon: Texture2D

## Saved for game loading
@export var anomalies: Array[Script] = []
@export var reward: Item
@export var level_range := Vector2i(1,12)
@export var room_count := 11
@export var discard_item: Item


## Local vars not saved to
var has_power_out := false
var anomaly_count := 0

func _init():
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'FALLBACK_REWARD_POOL': 'res://objects/items/pools/floor_clears.tres',
		'FALLBACK_COG_POOL': 'res://objects/cog/presets/pools/grunt_cogs.tres',
	})

func get_anomalies() -> Array[Script]:
	var mods: Array[Script] = []
	
	# Append a random amount of anomalies to the array
	var mod_count := RandomService.randi_range_channel('floor_mods', 0, 3)
	# Apply potential item anomaly boost
	if Util.get_player() and Util.get_player().stats and Util.get_player().stats.anomaly_boost != 0:
		mod_count += Util.get_player().stats.anomaly_boost
	var anomaly_files_pos: Array[String] = ANOMALIES_POSITIVE.duplicate()
	var anomaly_files_neutral: Array[String] = ANOMALIES_NEUTRAL.duplicate()
	var anomaly_files_neg: Array[String] = ANOMALIES_NEGATIVE_TRUE.duplicate()
	var pos_chance = 0.3333
	var neut_chance = 0.6666

	var no_negative_anomalies := false
	if Util.get_player() and Util.get_player().no_negative_anomalies:
		no_negative_anomalies = true
		anomaly_files_neg = []
	if floor_name == "Cog Golf Course" or floor_name == "D.A. Office":
		if mod_count < 3:
			mod_count+= 1
		pos_chance = 0.25
		neut_chance = 0.60
	for i in mod_count:
		var rng_val := RandomService.randf_channel('floor_mods')
		var mod_array: Array[String]
		if i == 0 and floor_name == "Cog Golf Course":
			rng_val = 0.9
		# Positive anomalies
		if rng_val <= pos_chance:
			mod_array = anomaly_files_pos
			if mod_array.size() == 0:
				mod_array = RandomService.array_pick_random('floor_mods', [anomaly_files_neutral, anomaly_files_neg])
		# Neutral anomalies
		elif rng_val <= neut_chance:
			mod_array = anomaly_files_neutral
			if mod_array.size() == 0:
				mod_array = RandomService.array_pick_random('floor_mods', [anomaly_files_pos, anomaly_files_neg])
		# Negative anomalies
		else:
			if no_negative_anomalies:
				continue

			mod_array = anomaly_files_neg
			if mod_array.size() == 0:
				mod_array = RandomService.array_pick_random('floor_mods', [anomaly_files_pos, anomaly_files_neutral])

		if mod_array.size() > 0:
			var new_mod: String = RandomService.array_pick_random('floor_mods', mod_array)
			var loaded_mod: Script = Util.universal_load(new_mod)
			if not loaded_mod in modifiers:
				mods.append(loaded_mod)
			mod_array.remove_at(mod_array.find(new_mod))
	if Util.floor_number >= 6:
		mods = add_unstable_core(mods)
	return mods
func add_true_neg_anomalies(anom_count) -> Array[Script]:
	var mod_array: Array[String] = ANOMALIES_NEGATIVE.duplicate()
	var mods: Array[Script] = []
	for i in anom_count:
		var rng_val := RandomService.randf_channel('floor_mods')
		var new_mod: String = RandomService.array_pick_random('floor_mods', mod_array)
		var loaded_mod: Script = Util.universal_load(new_mod)
		if not loaded_mod in modifiers:
			mods.append(loaded_mod)
		mod_array.remove_at(mod_array.find(new_mod))
	return mods
func randomize_details() -> void:
	clear()
	
	anomalies = get_anomalies()
	anomaly_count = anomalies.size()

	
	for anomaly: Script in anomalies:
		modifiers.append(anomaly)
	
	floor_difficulty = Util.floor_number + 1
	if not floor_difficulty in LEVEL_RANGES.keys():
		level_range = get_calculated_level_range(floor_difficulty)
	else:
		level_range.x = LEVEL_RANGES[floor_difficulty][0]
		level_range.y = LEVEL_RANGES[floor_difficulty][1]
	
	# Add onto the room count for the difficulty
	room_count += DIFFICULTY_ROOM_ADDITION * floor_difficulty
	
	# Get the default Cog Pool if none specified
	if not cog_pool:
		cog_pool = FALLBACK_COG_POOL
func anomaly_rebalance(qualitoon, floor_name) -> void:
	#this is pure slop but whatever
	var anom_add = 0
	if qualitoon >=3:
		print("rebalancing anomalies with qualitoon item of: ", qualitoon)
		clear()
		if floor_name == "Cog Golf Course":
			anom_add+= 1
		anom_add += qualitoon - 2
		anomalies = add_true_neg_anomalies(anom_add)
		for anomaly: Script in anomalies:
			modifiers.append(anomaly)
	anomaly_count = anomalies.size()

func anomaly_rebalance_on_set_anoms(qualitoon, floor_name) -> void:
	#this is pure slop but whatever
	var anom_add = 0
	if qualitoon >=3:
		print("rebalancing anomalies with qualitoon item of: ", qualitoon)
		if floor_name == "Cog Golf Course":
			anom_add+= 1
		anom_add += qualitoon - 2
		anomalies.append_array(add_true_neg_anomalies(anom_add))
	if anomalies.size() > 1:
		for i in range(1, anomalies.size()):
			var anomaly: Script = anomalies[i]
			modifiers.append(anomaly)
	anomaly_count = anomalies.size()	
## Simple failsafe backend for mods or if we're ever testing on floors > 5
## I will not be testing how well balanced this is
## You modders can do that one yourselves I believe in you
func get_calculated_level_range(difficulty: int) -> Vector2i:
	var base_range := Vector2i(LEVEL_RANGES[5][0], LEVEL_RANGES[5][1])
	base_range *= (Util.floor_number ** Globals.floor_difficulty_increase)
	return base_range

func randomize_item() -> void:
	if not reward_pool:
		reward_pool = FALLBACK_REWARD_POOL
	reward = ItemService.get_random_item(reward_pool,true)
	if not reward.evergreen:
		discard_item = reward
	else:
		reward = reward.duplicate()
	
	# Handle rerolls
	if not reward.s_reroll.is_connected(reward_rerolled):
		reward.s_reroll.connect(reward_rerolled)
	var model := reward.model.instantiate()
	model.hide()
	Util.add_child(model)
	if model.has_method("setup"):
		model.setup(reward)
	model.queue_free()
func randomize_good_item() -> void:
	if not reward_pool:
		reward_pool = FALLBACK_REWARD_POOL
	reward = ItemService.get_random_good_item()
	if not reward.evergreen:
		discard_item = reward
	else:
		reward = reward.duplicate()
	
	# Handle rerolls
	if not reward.s_reroll.is_connected(reward_rerolled):
		reward.s_reroll.connect(reward_rerolled)
	var model := reward.model.instantiate()
	model.hide()
	Util.add_child(model)
	if model.has_method("setup"):
		model.setup(reward)
	model.queue_free()

func get_snowflake() -> void:
	reward = load('res://objects/items/resources/passive/snowflake_treasure.tres').duplicate()
	var model := reward.model.instantiate()
	model.hide()
	Util.add_child(model)
	if model.has_method("setup"):
		model.setup(reward)
	model.queue_free()
#return load('res://objects/items/resources/passive/laff_boost.tres').duplicate()
func get_floor_item(floor_name) -> void:
	if not reward_pool:
		reward_pool = FALLBACK_REWARD_POOL
	reward = ItemService.get_random_item(reward_pool,true)
	if not reward.evergreen:
		discard_item = reward
	else:
		reward = reward.duplicate()
	
	# Handle rerolls
	if not reward.s_reroll.is_connected(reward_rerolled):
		reward.s_reroll.connect(reward_rerolled)
	print("qualitoon of reward ",reward.qualitoon)
	if reward.qualitoon >= 3:
		print("making floor harder")
	var model := reward.model.instantiate()
	model.hide()
	Util.add_child(model)
	if model.has_method("setup"):
		model.setup(reward)
	model.queue_free()

func reward_rerolled() -> void:
	randomize_item()

func clear() -> void:
	for i in range(anomalies.size() - 1, -1, -1):
		if modifiers.size() > i:
			modifiers.remove_at(i)
	anomalies.clear()


## ATTN MODDERS:
## Please do not remove marathon from this variable
## You will crash if marathon is added mid-floor
static var NEW_ANOMALY_BLOCKLIST := [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_volatile_market.gd",
]
## Returns a new, compatible anomaly during a game floor
func get_new_anomaly() -> Script:
	var new_anomaly : Script
	var no_negative : bool = Util.get_player().no_negative_anomalies
	var possible_anomalies : Array[String] = []
	possible_anomalies.append_array(ANOMALIES_POSITIVE)
	possible_anomalies.append_array(ANOMALIES_NEUTRAL)
	if not no_negative:
		possible_anomalies.append_array(ANOMALIES_NEGATIVE)
	
	while not new_anomaly and not possible_anomalies.is_empty():
		RandomService.array_shuffle_channel('true_random', possible_anomalies)
		new_anomaly = load(possible_anomalies.pop_back())
		if new_anomaly.resource_path in NEW_ANOMALY_BLOCKLIST:
			new_anomaly = null
			continue
		for mod in modifiers:
			if mod.resource_path == new_anomaly.resource_path:
				new_anomaly = null
				break
	return new_anomaly

func get_green_light_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_green_light.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	return mods

func get_gag_immunity_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_gag_immunities.gd"
	#var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/misc/floor_mod_expansion.gd"
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	return mods
func get_reorg_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_reorganization.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	return mods
func get_mixed_bag_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_mixed_bag.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	return mods
func get_larynx_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_larynx.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	var gag_immunity_mods := get_gag_immunity_anomaly()
	if gag_immunity_mods.size() > 0:
		mods.append(gag_immunity_mods[0])
	return mods
func get_annoying_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_annoying.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	var gag_immunity_mods := get_gag_immunity_anomaly()
	if gag_immunity_mods.size() > 0:
		mods.append(gag_immunity_mods[0])	
	return mods
func get_highly_unstable_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_highly_unstable_core.gd" 
	var loaded_mod: Script = Util.universal_load(new_mod)
	mods.append(loaded_mod)
	return mods
func get_no_anomaly() -> Array[Script]:
	var mods: Array[Script] = []
	return mods

func all_negative_anomalies() -> Array[Script]:
	var mods: Array[Script] = []
	for i in range(min(3, ANOMALIES_NEGATIVE.size())):
		var anomaly = ANOMALIES_NEGATIVE[i]
		var loaded_mod: Script = Util.universal_load(anomaly)
		mods.append(loaded_mod)
	if Util.floor_number != 2:
		var green_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_green_light.gd" 
		var loaded_green_mod: Script = Util.universal_load(green_mod)
		mods.append(loaded_green_mod)
	var immunity_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_gag_immunities.gd" 
	var loaded_immunity_mod: Script = Util.universal_load(immunity_mod)
	mods.append(loaded_immunity_mod)
	
	return mods
func all_positive_anomalies() -> Array[Script]:
	var mods: Array[Script] = []
	for anomaly in ANOMALIES_POSITIVE :
		var loaded_mod: Script = Util.universal_load(anomaly)
		mods.append(loaded_mod) 
	#var loaded_organic_mod: Script = Util.universal_load(organic_mod)
	#mods.append(loaded_organic_mod) # adding it again so its easier
	return mods
	
func scripted_details(anomaly_array) -> void:
	clear()
	anomalies = anomaly_array
	anomaly_count = anomaly_array.size()
	for anomaly: Script in anomaly_array:
		modifiers.append(anomaly)
	
	floor_difficulty = Util.floor_number + 1
	level_range.x = LEVEL_RANGES[floor_difficulty][0]
	level_range.y = LEVEL_RANGES[floor_difficulty][1]
	
	# Add onto the room count for the difficulty
	room_count += DIFFICULTY_ROOM_ADDITION * floor_difficulty
	
	#if floor_difficulty == 3: room_count = room_count * 1.2
	if room_count % 2 == 0:
		room_count += 1
	
	# Get the default Cog Pool if none specified
	if not cog_pool:
		cog_pool = FALLBACK_COG_POOL.load()
func add_unstable_core(anom_array) -> Array:
	if Util.floor_number >= 6:
		var new_mod: String = "res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_unstable_core.gd" 
		var loaded_mod: Script = Util.universal_load(new_mod)
		anom_array.append(loaded_mod)
	return anom_array
		
	
