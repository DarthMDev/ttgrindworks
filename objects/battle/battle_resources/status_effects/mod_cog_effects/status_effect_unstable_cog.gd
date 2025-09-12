@tool
extends StatusEffect


const MOD_EFFECTS : Array[StatusEffect] = [
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sheer_force.tres"), #13 s 0
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_thorns.tres"), #14 s  1
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_alphabet.tres"), #15 s 2
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_laborious.tres"), #17 s 3
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_whistleblower_fan.tres"), #20 s 4
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sniper.tres"), #23 s 5
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_bookkeeper_fan.tres"), #24 6
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_hp_guy.tres"), #25 7
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_confused.tres") #  s  8
]

func apply() -> void:
	if not MOD_EFFECTS.is_empty():
		var mod_effect: StatusEffect = RandomService.array_pick_random('mod_cog_effects', MOD_EFFECTS).duplicate()
		mod_effect.target = target
		mod_effect.rounds = 0
		mod_effect.unstable = true
		manager.add_status_effect(mod_effect)
