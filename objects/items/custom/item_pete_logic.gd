extends ItemScript

const BEAN_LIMIT := 75
const OVERFLOW_UI := "res://objects/player/ui/pete_voucher_progress/bean_voucher_meter.tscn"
const UI_SCRIPT_PATH := "res://objects/player/ui/pete_voucher_progress/bean_voucher_meter.gd"
const BONUS_COLOR := Color(0.426, 0.961, 0.47, 1.0)

var player: Player:
	get: return Util.get_player()

var current_button: GagButton
var current_track: TrackElement
var bean_ui: Control
var excess_beans: int = 0:
	set(x):
		if res:
			res.arbitrary_data['excess_beans'] = x
	get:
		if not res: return 0
		if not res.arbitrary_data['excess_beans']: return 0
		return res.arbitrary_data['excess_beans']
var res: Item
var current_chain := 0

func on_collect(item: Item, _model) -> void:
	setup(item)

func on_load(item: Item) -> void:
	setup(item)
	bean_ui.excess_beans = excess_beans

func setup(item: Item) -> void:
	res = item
	BattleService.s_cog_died.connect(on_cog_died)
	BattleService.s_battle_started.connect(on_battle_start)
	BattleService.s_round_ended.connect(on_round_ended)
	Globals.s_shop_spawned.connect(on_shop_spawn)
	player.stats.s_money_changed.connect(on_money_changed)
	_initialize_bean_ui()

func _initialize_bean_ui() -> void:
	for node in player.gui.get_children():
		if node.get_script():
			if node.get_script().resource_path == UI_SCRIPT_PATH:
				bean_ui = node
				return
	bean_ui = load(OVERFLOW_UI).instantiate()
	player.gui.add_child(bean_ui)

func on_cog_died(cog: Cog) -> void:
	player.stats.add_money(get_bean_reward(cog))

const BEANS_PER_LEVEL := 2.0 / 3.0
const BONUS_ROUND1 := 1.5
const CHAIN_BONUS := 0.1

func get_bean_reward(cog: Cog) -> int:
	if not is_instance_valid(BattleService.ongoing_battle):
		return 1
	current_chain += 1

	var bean_total := ceili(cog.level * BEANS_PER_LEVEL)
	var _base_bean_total := bean_total
	var bean_diff := 0
	# Bonuses?
	if BattleService.ongoing_battle.current_round == 1:
		bean_total = ceili(BONUS_ROUND1 * bean_total)
		bean_diff = bean_total - _base_bean_total
		show_bonus("Round 1 KO!", bean_diff)
	if current_chain > 1:
		var chain_bonus := 1.0 + (CHAIN_BONUS * current_chain)
		bean_total = ceili(chain_bonus * bean_total)
		bean_diff = bean_total - _base_bean_total
		show_bonus("Combo!", bean_diff)
	return bean_total

func on_battle_start(battle : BattleManager) -> void:
	await battle.s_ui_initialized
	battle.s_battle_ended.connect(on_battle_end)

func reasses_track() -> void:
	if current_track:
		clear_track()
	current_track.refresh()

func clear_track() -> void:
	current_track = null

func get_random_gag() -> ToonAttack:
	var track: Track = player.stats.character.gag_loadout.loadout.pick_random()
	var index := randi_range(get_min_gag_level(track), player.stats.gags_unlocked[track.track_name] - 1)
	return track.gags[index]

func get_min_gag_level(track: Track) -> int:
	var absolute_min := maxi(Util.floor_number - 2, 0)
	return mini(absolute_min, player.stats.gags_unlocked[track.track_name] - 1)

func find_gag_button(gag: ToonAttack) -> GagButton:
	var track := player.stats.character.gag_loadout.get_action_track(gag)
	var element := get_track_element(track)
	for button: GagButton in element.gag_buttons:
		if button.image == gag.icon:
			return button
	return element.gag_buttons[track.gags.find(gag)]

func show_bonus(bonus_name: String, extra_beans: int) -> void:
	Util.get_player().boost_queue.queue_text("%s +%s Bean%s!" % [bonus_name, extra_beans, ToonUtils.plural(extra_beans)], BONUS_COLOR)

func get_track_element(track: Track) -> TrackElement:
	for element: TrackElement in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
		if element.track == track:
			return element
	return

func on_battle_end() -> void:
	current_button = null
	current_track = null

## Pete's Shops are meant to be more alluring
## We accomplish this by giving a chance to get special items 
## instead of shop items
const SPECIAL_SHOP_CHANCE := 0.2
const REPLACEMENT_POOL := "res://objects/items/pools/special_items.tres"
func on_shop_spawn(shop: ToonShop) -> void:
	for world_item: WorldItem in shop.world_items:
		if RNG.channel(RNG.ChannelPeteShopItems).randf() < SPECIAL_SHOP_CHANCE:
			specialize_shop_item(world_item, shop)

func specialize_shop_item(world_item: WorldItem, shop: ToonShop) -> void:
	world_item.pool = ItemService.pool_from_path(REPLACEMENT_POOL)
	if ItemService.seen_items.has(world_item.item):
		ItemService.seen_items.erase(world_item.item)
	world_item.reroll()
	shop.stored_prices[shop.world_items.find(world_item)] = shop.get_price(world_item)

func on_money_changed(_amt := 0) -> void:
	await get_tree().process_frame
	if player.stats.money > BEAN_LIMIT:
		var diff := player.stats.money - BEAN_LIMIT
		player.stats.money = BEAN_LIMIT
		bean_ui.increase_beans(diff)

func _process(_delta: float) -> void:
	if bean_ui:
		excess_beans = bean_ui.excess_beans

func on_round_ended(_battle) -> void:
	current_chain = 0
