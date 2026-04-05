extends ItemScript

const BOOST_STATS = ['damage','defense','evasiveness','luck','speed','hp']
const STAGGER_TIME := 0.5
const BOOST_KEEP := 0.1

var boosters: Array[StatMultiplier] = []

var text_queue: Array[String] = []
var can_queue_text := true

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	Util.s_floor_started.connect(on_floor_start)
	BattleService.s_battle_started.connect(battle_started)

func on_floor_start(game_floor: GameFloor) -> void:
	game_floor.s_floor_ended.connect(on_floor_end)
	for stat in BOOST_STATS:
		if not stat == 'hp':
			initialize_booster(stat)

func initialize_booster(stat: String) -> StatMultiplier:
	var booster := StatMultiplier.new()
	booster.stat = stat
	booster.amount = 0.0
	Util.get_player().stats.multipliers.append(booster)
	boosters.append(booster)
	return booster

# Clear out boosters at end of floor
func on_floor_end() -> void:
	var player := Util.get_player()
	for i in range(player.stats.multipliers.size() - 1, -1, -1):
		if player.stats.multipliers[i] in boosters:
			var booster: StatMultiplier = player.stats.multipliers[i]
			player.stats.multipliers.remove_at(i)
			player.stats.set(booster.stat, player.stats.get(booster.stat) + (booster.amount * BOOST_KEEP))
	boosters.clear()


func get_current_battle() -> BattleManager:
	if is_instance_valid(BattleService.ongoing_battle):
		return BattleService.ongoing_battle
	return null

func battle_started(battle: BattleManager) -> void:
	battle.s_action_started.connect(on_action_start)

func on_action_start(action: BattleAction) -> void:
	if action is GagTrap:
		action.s_activate.connect(add_booster)

func add_booster() -> void:
	var boost_stats = BOOST_STATS.duplicate(true)
	if Util.get_player().stats.hp == Util.get_player().stats.max_hp:
		boost_stats.erase('hp')
	var stat: String = boost_stats.pick_random()
	if stat == 'hp':
		Util.get_player().quick_heal(int(ceil(Util.get_player().stats.max_hp * 0.25)))
	else:
		var booster: StatMultiplier
		for boost in boosters:
			if boost.stat == stat:
				booster = boost
		if not booster:
			booster = initialize_booster(stat)
		# Increase the booster amount
		booster.amount += 0.05 * float(randi() % 2 + 1)
		queue_text(stat.to_upper() + " UP!")
		print("%.2f %s boost applied" % [booster.amount, stat])

func do_battle_text(text: String) -> void:
	var battle_manager: BattleManager = BattleService.ongoing_battle
	if is_instance_valid(battle_manager):
		battle_manager.battle_text(Util.get_player(), text, Color.GREEN, Color.DARK_GREEN)

func queue_text(text: String) -> void:
	if text_queue.is_empty() and can_queue_text:
		run_text(text)
	else:
		text_queue.append(text)

func run_text(text: String) -> void:
	do_battle_text(text)
	can_queue_text = false
	await Task.delay(STAGGER_TIME)
	if text_queue.is_empty():
		can_queue_text = true
	else:
		run_text(text_queue.pop_front())
