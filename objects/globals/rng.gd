@tool
extends Node

#region Channel Names
# Base
# Note: It's not recommended to use the true_random channel.
# Instead, just use the built-in random functions.
# It may still be used for some legacy stuff or for other routes that rely on being passed a channel.
const ChannelTrueRandom = &"true_random"
const ChannelBaseSeed = &"base_seed"
const ChannelMinigames = &"minigames"

# Floor generation
const ChannelFloors = &"floors"
const ChannelFloorMods = &"floor_mods"
const ChannelFloorDiffRolls = &"floor_diff_rolls"
const ChannelBattleRatio = &"battle_ratio"
const ChannelRoomLogic = &"room_logic"
const ChannelRemainingRooms = &"remaining_rooms"
const ChannelRoomDiffRolls = &"room_diff_rolls"
const ChannelStrangerRoll = &"stranger_roll"

# Item Generation
const ChannelGagRolls = &"gag_rolls"
const ChannelLaffRolls = &"laff_rolls"
const ChannelBeanRolls = &"bean_rolls"
const ChannelActiveItemDiscard = &"active_item_discard"
const ChannelItemQualityRoll = &"item_quality_roll"
const ChannelBattleChestOverrides = &"battle_chest_overrides"
const ChannelShopItemRandom = &"shop_item_random"
const ChannelChestRolls = &"chest_rolls"
const ChannelGagVouchers = &"gag_vouchers"
const ChannelBeanVouchers = &"bean_vouchers"
const ChannelOverfillBeanVouchers = &"overfill_bean_vouchers"
const ChannelGagFrames = &"gag_frames"
const ChannelTreasureRerollChance = &"treasure_reroll_chance"
const ChannelLaffBoosts = &"laff_boosts"

# Cogs
const ChannelCogCounts = &"cog_counts"
const ChannelModCogChance = &"mod_cog_chance"
const ChannelModCogEffects = &"mod_cog_effects"
const ChannelSkelecogChance = &"skelecog_chance"
const ChannelFusionChance = &"fusion_chance"
const ChannelCogLevels = &"cog_levels"
const ChannelCogPoolChance = &"cog_pool_chance"
const ChannelCogDNA = &"cog_dna"

# Quests
const ChannelQuests = &"quests"
const ChannelCogQuestTypes = &"cog_quest_types"

# Doodles
const ChannelDoodleDig = &"doodle_dig"
const ChannelDoodleChests = &"doodle_chests"
const ChannelDoodleMood = &"doodle_mood"
const ChannelDoodleDNA = &"doodle_dna"
const ChannelDoodleNames = &"doodle_names"
const ChannelDoodleDescriptions = &"doodle_descriptions"

# Obstacles
const ChannelPuzzles = &"puzzles"
const ChannelMoles = &"moles"
const ChannelMoleQuadrant = &"mole_quadrant"
const ChannelMazeSizes = &"maze_sizes"
const ChannelMintConveyor = &"mint_conveyor"
const ChannelMintConveyorLava = &"mint_conveyor_lava"
const ChannelSandTrapMoles = &"sand_trap_moles"

# Specific Bosses
const ChannelGoonBossProxies = &"goon_boss_proxies"
const ChannelMoleBoss = &"mole_boss"
const ChannelGoldenGoose = &"golden_goose"
const ChannelMoltenChaseGeneration = &"molten_chase_generation"
const ChannelHeadOfSecurity = &"head_of_security"

# Specific Items
const ChannelMasqueradeStats = &"masquerade_stats"
const ChannelBeeHiveHairdoStats = &"bee_hive_hairdo_stats"
const ChannelAccessoryTrunkItems = &"accessory_trunk_items"
const ChannelGumballMachineRolls = &"gumball_machine_rolls"
const ChannelMoneybagsCoin = &"moneybags_coin"
const ChannelWhiteOutFloor = &"white_out_floor"
const ChannelCalculatorHPMods = &"calculator_hp_mods"
const ChannelRecycleBinStats = &"recycle_bin_stats"
const ChannelSpinningTop = &"spinning-top"
const ChannelPrankBeanJarRolls = &"prank_bean_jar_rolls"
const ChannelPhilosophersStoneRolls = &"philosophers_stone_rolls"
const ChannelRolodexRolls = &"rolodex_rolls"

# Specific Characters
const ChannelPeteShopItems = &"pete_shop_items"
const ChannelWheezerAbility = &"wheezer_ability"
const ChannelMysteryToonLaff = &"mystery_toon_laff"
const ChannelMysteryToonStats = &"mystery_toon_stats"
const ChannelMysteryToonGags = &"mystery_toon_gags"

# Anomalies
const ChannelAnomalyReorg = &"anomaly_reorg"
const ChannelOverstockFreeItem = &"overstock_free_item"
const ChannelToughCrowdMod = &"tough_crowd_mod"
const ChannelHauntedCGCv2 = &"haunted_cgc_v2"
const ChannelMoltenBuckets = &"molten_buckets"
const ChannelDoubleTroublev2 = &"double_trouble_v2"

#endregion

## Simplified seeding for runs
const SEED_MAX := 999999999999

## Base seed
var base_seed: int
var is_custom_seed := false
## String version of seed (if it exists, it will take priority on the pause menu)
var _str_seed := ""

## Channels
var channels: Dictionary[StringName, ToonNumGen] = {}

func add_channel(channel_name: StringName) -> void:
	var base_channel_seed := base_seed
	base_channel_seed += channel_name.hash()
	base_channel_seed *= roundi(base_channel_seed / channel_name.hash())
	var new_rng := ToonNumGen.new(base_channel_seed)
	if channel_name == ChannelTrueRandom:
		new_rng.true_random = true
	if channel_name == ChannelBaseSeed:
		new_rng.lock_state = true
	channels[channel_name] = new_rng

func channel(channel_name: StringName) -> ToonNumGen:
	if channel_name not in channels:
		add_channel(channel_name)
	return channels[channel_name]

#region Seeding

func generate_seed() -> int:
	randomize()
	_str_seed = gen_random_string_seed()
	base_seed = get_numerical_seed_from_string(_str_seed)
	return base_seed

func set_seed(new_seed: int) -> void:
	randomize()
	base_seed = new_seed

func get_numerical_seed_from_string(str_seed: String) -> int:
	if str_seed.is_valid_int():
		return int(str_seed)

	return str_seed.hash() % SEED_MAX

func gen_random_string_seed() -> String:
	var new_seed: String = ""
	var choices: Array = ToonUtils.get_alphabet_chars(true) + ToonUtils.get_numerical_chars()
	for i: int in randi_range(4, 12):
		new_seed += choices.pick_random()

	return new_seed

#endregion

func _ready() -> void: 
	generate_seed()
	if not Engine.is_editor_hint():
		SaveFileService.s_reset.connect(reset)

func reset() -> void:
	channels.clear()
	_str_seed = ""

func load_from_run_file(file: SaveFile) -> void:
	base_seed = file.current_seed
	_str_seed = file.str_seed
	is_custom_seed = file.is_custom_seed
	channels.clear()
	for channel_name: StringName in file.seed_channels.keys():
		channels[channel_name] = ToonNumGen.new(base_seed, file.seed_channels[channel_name])
