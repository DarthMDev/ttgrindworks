@tool
extends StatusEffect
class_name StatusEffectModCog

static var MOD_EFFECTS: Array[StatusEffect] = [
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_investment.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_pinpoint.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_insured.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_diverse_portfolio.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_banker.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_embezzler.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_tax_collector.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_fire_sale.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_agile.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_leverage.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_interference.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_wheelhouse.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_asset_protection.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_sturdy.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_witness_protection.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_backtalker.tres"),
	preload("res://objects/battle/battle_resources/status_effects/resources/mod_cog_toxic.tres"),
]

func apply() -> void:
	if not MOD_EFFECTS.is_empty():
		var mod_effect: StatusEffect = RNG.channel(RNG.ChannelModCogEffects).pick_random(MOD_EFFECTS).duplicate(true)
		mod_effect.target = target
		manager.add_status_effect(mod_effect)
