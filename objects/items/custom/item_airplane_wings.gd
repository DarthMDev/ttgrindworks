extends ItemScript

const BATTLE_STATS: Array[String] = [
	'damage', 'defense', 'evasiveness', 'luck'
]

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_ended.connect(on_round_ended)

func on_round_ended(battle: BattleManager) -> void:
	var player := Util.get_player()
	var stat: String = BATTLE_STATS.pick_random()
	battle.battle_stats[player].set(stat, battle.battle_stats[player].get(stat) + 0.05)
