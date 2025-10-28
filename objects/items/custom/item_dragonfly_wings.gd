extends ItemScript

const StartDamage := 0.5
const FinalDamage := 0.0
const TotalTime := 15.0 * 60.0  # 10 minutes total
const TickTime := 10.0  # Ticks every 10 seconds
const DiffPerTick: float = (StartDamage + abs(FinalDamage)) / (TotalTime / TickTime)

var item: Item
var dmg_mult: StatMultiplier

var _start_time: float
var _tick_task: Task

var damage_remaining: float:
	get: return item.arbitrary_data["damage_remaining"]
	set(x): item.arbitrary_data["damage_remaining"] = x


func on_collect(_item: Item, _object: Node3D) -> void:
	_start_time = Time.get_unix_time_from_system()
	_item.arbitrary_data["damage_remaining"] = StartDamage
	setup(_item)

func on_load(_item: Item) -> void:
	setup(_item)

func on_item_removed() -> void:
	if _tick_task:
		_tick_task = _tick_task.cancel()
	Util.get_player().stats.multipliers.erase(dmg_mult)

func setup(_item: Item) -> void:
	item = _item

	if not Util.get_player():
		await Util.s_player_assigned

	create_multiplier()

	if damage_remaining > FinalDamage:
		_tick_task = Task.delayed_call(self, TickTime, on_tick)

func on_tick():
	damage_remaining -= DiffPerTick
	dmg_mult.amount = damage_remaining
	if damage_remaining <= FinalDamage:
		return

	return Task.AGAIN

func create_multiplier() -> void:
	dmg_mult = StatMultiplier.new()
	dmg_mult.stat = "damage"
	dmg_mult.amount = damage_remaining
	dmg_mult.additive = true
	Util.get_player().stats.multipliers.append(dmg_mult)
