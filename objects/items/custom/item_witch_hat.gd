extends ItemScript

const POISON_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_poison.tres")
const EFFECT_RATIO := 0.4

func setup() -> void:
	BattleService.s_round_started.connect(on_round_started)

func on_round_started(actions : Array[BattleAction]) -> void:
	for action in actions:
		if action is GagSquirt:
			action.s_hit.connect(squirt_hit.bind(action))

func squirt_hit(action : GagSquirt) -> void:
	var gag_damage := action.damage
	var cog: Cog = action.targets[0]
	if cog.stats.hp > 0:
		apply_poison_effect(cog, get_damage(gag_damage))

func apply_poison_effect(cog : Cog, damage : int) -> void:
	var poison_effect := POISON_EFFECT.duplicate()
	poison_effect.target = cog
	poison_effect.amount = damage
	poison_effect.rounds = -1
	poison_effect.icon = load("res://ui_assets/battle/statuses/poison.png")
	BattleService.ongoing_battle.add_status_effect(poison_effect)

func get_damage(gag_damage : int) -> int:
	return ceili(gag_damage * EFFECT_RATIO)

func on_collect(_item : Item, _model : Node3D) -> void:
	setup()

func on_load(_item : Item) -> void:
	setup()
