extends ItemSpirit

@export var mult_stat := 'defense'
@export var mult_factor := -(2.0/3.0)
@export var mult_additive = false

var multiplier : StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	maximize_laff()
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	connect_impure_function(apply_healing_penalty, Util.get_player().stats.s_hp_gained)
	if !spirit_purified:
		create_multiplier()

func purify() -> void:
	super()
	Util.get_player().stats.multiplier.erase(multiplier)

func maximize_laff() -> void:
	var stats = Util.get_player().stats
	stats.max_hp = 999 + stats.laff_boost_boost
	stats.hp = stats.max_hp

func create_multiplier() -> void:
	multiplier = StatMultiplier.new()
	multiplier.stat = mult_stat
	multiplier.amount = mult_factor
	multiplier.additive = mult_additive
	Util.get_player().stats.multipliers.append(multiplier)

func apply_healing_penalty(hp: int) -> void:
	Util.get_player().stats.max_hp -= hp
