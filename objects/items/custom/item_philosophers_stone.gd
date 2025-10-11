extends ItemScript

const DebugPrint := true

const GoldUpgradeChance := 0.2
const SpecialUpgradeChance := 0.1
const ExplodeChance := 0.12

const POOL_REWARDS := "res://objects/items/pools/rewards.tres"
const POOL_PROGRESSIVES := "res://objects/items/pools/progressives.tres"
const POOL_SPECIAL := "res://objects/items/pools/special_items.tres"
const NOTHING_ITEM := "res://objects/items/resources/passive/nothing.tres"

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()
	teehee()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	Globals.s_chest_spawned.connect(_chest_spawned)

func _chest_spawned(chest: TreasureChest) -> void:
	if chest.scripted_progression:
		return
	if chest.override_item:
		return
	if chest.unopenable:
		return

	var _rng: ToonNumGen = RNG.channel(RNG.ChannelPhilosophersStoneRolls)
	if chest.get_current_texture() != TreasureChest.BOSS_TEXTURE:
		# Silver -> Gold
		if chest.item_pool.resource_path == POOL_PROGRESSIVES and gold_upgrade_roll():
			make_upgradeable(chest, upgrade_gold)
		# Gold -> Special
		if chest.item_pool.resource_path == POOL_REWARDS and special_upgrade_roll():
			make_upgradeable(chest, upgrade_special)

	if explode_roll():
		chest.override_item = load(NOTHING_ITEM)
		chest.s_opened.connect(_explode_chest_opened.bind(chest))

func _explode_chest_opened(chest: TreasureChest) -> void:
	await Task.delay(1.0)
	teehee()
	Util.get_player().boost_queue.queue_text("You snooze you lose!", Globals.dna_colors["slate_blue"].lerp(Color.WHITE, 0.5))
	chest.vanish()
	return

func teehee() -> void:
	AudioManager.play_sound(load("res://audio/sfx/items/avatar_emotion_laugh.ogg"), 0.0, "Boomy")

func explode_roll() -> bool:
	var _roll := RNG.channel(RNG.ChannelPhilosophersStoneRolls).randf()
	var _chance := Util.get_player().stats.get_luck_weighted_chance(ExplodeChance, ExplodeChance * 0.5, 2.0)
	if DebugPrint: print("PS - Explode Roll: Needed %s or lower, got %s" % [_chance, _roll])
	return _roll < _chance

func gold_upgrade_roll() -> bool:
	var _roll := RNG.channel(RNG.ChannelPhilosophersStoneRolls).randf()
	var _chance := Util.get_player().stats.get_luck_weighted_chance(GoldUpgradeChance, GoldUpgradeChance * 2.0, 2.0)
	if DebugPrint: print("PS - Gold Roll: Needed %s or lower, got %s" % [_chance, _roll])
	return _roll < _chance

func special_upgrade_roll() -> bool:
	var _roll := RNG.channel(RNG.ChannelPhilosophersStoneRolls).randf()
	var _chance := Util.get_player().stats.get_luck_weighted_chance(SpecialUpgradeChance, SpecialUpgradeChance * 1.5, 2.0)
	if DebugPrint: print("PS - Special Roll: Needed %s or lower, got %s" % [_chance, _roll])
	return _roll < _chance

func make_upgradeable(chest: TreasureChest, upgrade_func: Callable) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_layer_value(1, true)
	area.set_collision_mask_value(2, true)
	var cs3d := CollisionShape3D.new()
	var _sphere := SphereShape3D.new()
	_sphere.radius = 6.0
	cs3d.shape = _sphere
	area.add_child(cs3d)
	area.body_entered.connect(_entered_upgrade_coll.bind(chest, upgrade_func), CONNECT_ONE_SHOT)
	chest.add_child(area)

func _entered_upgrade_coll(body: Node3D, chest: TreasureChest, upgrade_func: Callable) -> void:
	if body is Player:
		await get_tree().process_frame
		await get_tree().process_frame
		upgrade_func.call(chest)

func upgrade_gold(chest: TreasureChest) -> void:
	if chest.item_pool.resource_path != POOL_PROGRESSIVES:
		# Filter out any stragglers that aren't actually silver chests
		return
	if chest.get_current_texture() == TreasureChest.BOSS_TEXTURE:
		return
	if not is_instance_valid(chest):
		return

	chest.item_pool = ItemService.get_centralized_pool(load(POOL_REWARDS))
	if RNG.channel(RNG.ChannelChestRolls).randf() < chest.REWARD_OVERRIDE_CHANCE:
		chest.override_replacement_rolls = true
	chest.show_dust_cloud()
	Util.get_player().boost_queue.queue_text("Gold Upgrade!", Color.GOLDENROD)
	AudioManager.play_sound(load("res://audio/sfx/misc/MG_pairing_match_bonus_both.ogg"))

	if special_upgrade_roll():
		# If bro is really lucky
		await get_tree().process_frame
		upgrade_special(chest)

func upgrade_special(chest: TreasureChest) -> void:
	if chest.item_pool.resource_path != POOL_REWARDS:
		# Filter out any stragglers that aren't actually gold chests
		return
	if chest.get_current_texture() == TreasureChest.BOSS_TEXTURE:
		return
	if not is_instance_valid(chest):
		return

	chest.item_pool = ItemService.get_centralized_pool(load(POOL_SPECIAL))
	chest.override_replacement_rolls = true
	chest.show_dust_cloud()
	Util.get_player().boost_queue.queue_text("Special Upgrade!", Color.AQUA)
	AudioManager.play_sound(load("res://audio/sfx/misc/Holy_Mackerel.ogg"))
