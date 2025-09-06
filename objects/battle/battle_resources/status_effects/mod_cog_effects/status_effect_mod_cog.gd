@tool
extends StatusEffect


const MOD_EFFECTS : Array[StatusEffect] = [
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_investment.tres"),
	#preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_pinpoint.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_insured.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_diverse_portfolio.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_banker.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_embezzler.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_tax_collector.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_fire_sale.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_agile.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_leverage.tres"),
]
var force = false
var cheat_index = -1
func apply() -> void:
	if not MOD_EFFECTS.is_empty():
		var mod_effect: StatusEffect = RandomService.array_pick_random('mod_cog_effects', MOD_EFFECTS).duplicate()
		mod_effect.target = target
		manager.add_status_effect(mod_effect)


func choose_random_cheat() -> StatusEffect:
	var mod_effect : StatusEffect
	mod_effect = RandomService.array_pick_random('mod_cog_effects', MOD_EFFECTS)
	return mod_effect
