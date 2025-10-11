extends ItemScript

const CRIT_BONUS := 0.04

var crit_sum := 0.0

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_toon_crit.connect(crit)
	BattleService.s_toon_didnt_crit.connect(didnt_crit)
	BattleService.s_battle_started.connect(func(_x=null): battle_started())

func battle_started() -> void:
	BattleService.ongoing_battle.battle_stats[Util.get_player()].luck += crit_sum
	print_crit()

func didnt_crit() -> void:
	BattleService.ongoing_battle.battle_stats[Util.get_player()].luck += CRIT_BONUS
	crit_sum += CRIT_BONUS
	print_crit()

func crit() -> void:
	BattleService.ongoing_battle.battle_stats[Util.get_player()].luck -= crit_sum
	crit_sum = 0.0
	print_crit()

func print_crit() -> void:
	print('Archer: New crit chance: %s' % BattleService.ongoing_battle.battle_stats[Util.get_player()].luck)
