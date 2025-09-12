extends ItemScript

const percent_heal := 0.02

const tiara_status = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_faded_tiara.tres")
var total_regened = 0
func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(battle_start)
	BattleService.s_battle_ending.connect(on_battle_ending)


func battle_start(manager: BattleManager) -> void:
	var toon_regen = tiara_status.duplicate()
	toon_regen.quality = StatusEffect.EffectQuality.POSITIVE
	toon_regen.target = Util.get_player()
	toon_regen.rounds = -1
	manager.add_status_effect(toon_regen)





func on_battle_ending() -> void:
	print("ok")
