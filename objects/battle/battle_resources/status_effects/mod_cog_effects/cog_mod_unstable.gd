@tool
extends StatusEffect

const CHEAT_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/status_effect_unstable_cog.tres")
func apply() -> void:
	print("Unstable effect")
	var new_boost := CHEAT_REFERENCE.duplicate()
	new_boost.quality = StatusEffect.EffectQuality.POSITIVE
	new_boost.target = target
	manager.add_status_effect(new_boost)

	


func get_status_name() -> String:
	return "Unstable"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/Overcharged.png")
	
func renew() -> void:
	var new_boost := CHEAT_REFERENCE.duplicate()
	new_boost.quality = StatusEffect.EffectQuality.POSITIVE
	new_boost.target = target
	manager.add_status_effect(new_boost)
	
