extends ItemScript

const percent_heal := 0.02

const regen_status = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_regeneration.tres")
var total_regened = 0
func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(battle_start)
	BattleService.s_battle_ending.connect(on_battle_ending)
	BattleService.s_round_ended.connect(on_round_ended) #only for debug

func battle_start(manager: BattleManager) -> void:
	var toon_regen = regen_status.duplicate()
	toon_regen.quality = StatusEffect.EffectQuality.POSITIVE
	toon_regen.target = Util.get_player()
	toon_regen.amount = round(Util.get_player().stats.max_hp * percent_heal)
	toon_regen.rounds = -1
	toon_regen.instant_effect = false
	manager.add_status_effect(toon_regen)

func on_round_ended(manager: BattleManager) -> void:
	var estimated_gain = round(Util.get_player().stats.max_hp * percent_heal * Util.get_player().stats.get_stat("healing_effectiveness"))
	total_regened+= estimated_gain
	Globals.healed_from_winter_hat+= estimated_gain




func on_battle_ending() -> void:
	print("ok")
