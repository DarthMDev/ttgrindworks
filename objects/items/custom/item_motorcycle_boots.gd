extends ItemScript

const BOOST_AMT := 0.25

var damage_mult: StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	damage_mult = StatMultiplier.new()
	damage_mult.additive = true
	damage_mult.stat = 'damage'
	damage_mult.amount = 0.0
	Util.get_player().stats.multipliers.append(damage_mult)
	
	BattleService.s_round_ended.connect(on_round_start)
	BattleService.s_cog_died.connect(on_cog_died)
	BattleService.s_battle_ended.connect(on_round_start)

func on_round_start(_battle = null) -> void:
	reset_boost()

func reset_boost() -> void:
	damage_mult.amount = 0.0

func on_cog_died(_cog) -> void:
	if not is_instance_valid(BattleService.ongoing_battle): return
	damage_mult.amount += BOOST_AMT
	Util.get_player().boost_queue.queue_text("Rev up!", Color(0.937, 0.278, 0.278))
