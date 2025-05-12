extends Resource
class_name FloorVariant

## Default Item Pool
var FALLBACK_REWARD_POOL: ItemPool
## Default Cog Pool
var FALLBACK_COG_POOL: CogPool
## Amount of rooms to add per difficulty (includes connectors)
const DIFFICULTY_ROOM_ADDITION := 2

const ANOMALIES_POSITIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overheal.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_record_profits.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_organic_gags.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_down.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_inspiration.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_victory_cry.gd",
]
const ANOMALIES_NEUTRAL: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_reorganization.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_volatile_market.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_mixed_bag.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_status_report.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_stagnant_air.gd"
]
const ANOMALIES_NEGATIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_level_up.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_out_of_touch.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_safety_violations.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_time_crunch.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_inflation.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_double_trouble.gd",
]

const LEVEL_RANGES: Dictionary[int, Array] = {
	0: [1, 3],
	1: [2, 5],
	2: [3, 7],
	3: [6, 9],
	4: [8, 12],
	5: [9, 15],
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
	var anomaly_files_neg: Array[String] = ANOMALIES_NEGATIVE.duplicate()

	var no_negative_anomalies := false
	if Util.get_player() and Util.get_player().no_negative_anomalies:
		no_negative_anomalies = true
		anomaly_files_neg = []

	for i in mod_count:
		var rng_val := RandomService.randf_channel('floor_mods')
		var mod_array: Array[String]
		# Positive anomalies
		if rng_val <= 0.3333:
			mod_array = anomaly_files_pos
			if mod_array.size() == 0:
				mod_array = RandomService.array_pick_random('floor_mods', [anomaly_files_neutral, anomaly_files_neg])
		# Neutral anomalies
		elif rng_val <= 0.6666:
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

func reward_rerolled() -> void:
	randomize_item()

func clear() -> void:
	for i in range(anomalies.size() - 1, -1, -1):
		if modifiers.size() > i:
			modifiers.remove_at(i)
	anomalies.clear()


const NEW_ANOMALY_BLOCKLIST := [
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
