extends ItemScript

const BoostRange: Vector2 = Vector2(0.02, 0.04)
const StatChoices: Array = [
	["damage", Color("fc954cff")],
	["defense", Color("5c81edff")],
	["evasiveness", Color("e366d4ff")],
	["luck", Color("53db6cff")],
	["speed", Color("fa6f5cff")],
]
const ClockSfxChoices: Array[String] = ["01", "04", "05", "06", "07", "08", "10", "11"]

var player: Player
var curr_active_item: ItemActive

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	player = Util.get_player()
	player.stats.s_active_item_changed.connect(on_active_item_changed)
	if player.stats.current_active_item:
		on_active_item_changed(player.stats.current_active_item)

func on_active_item_changed(active_item: ItemActive) -> void:
	if curr_active_item and curr_active_item.node:
		curr_active_item.node.s_used.disconnect(on_item_use)
	curr_active_item = active_item
	if curr_active_item and curr_active_item.node:
		curr_active_item.node.s_used.connect(on_item_use)

func on_item_use() -> void:
	var choice: Array = StatChoices.pick_random()

	var boost_amt: float = randf_range(BoostRange.x, BoostRange.y)
	player.stats[choice[0]] += boost_amt
	if BattleService.ongoing_battle:
		BattleService.ongoing_battle.battle_stats[player][choice[0]] += boost_amt

	player.boost_queue.queue_text("%s Up!" % choice[0].capitalize(), choice[1])
	AudioManager.play_sound(load("res://audio/sfx/items/clock%s.ogg" % ClockSfxChoices.pick_random()), 2.0)
