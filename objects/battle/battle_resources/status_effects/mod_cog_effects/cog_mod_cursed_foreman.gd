@tool
extends StatusEffect

const Curse_Status_Reference := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_curse.tres")


func apply() -> void:
	var cog: Cog = target
	#("Appied Cursed Foreman")

	

func on_death() -> void:
	var status_effect := Curse_Status_Reference.duplicate()
	status_effect.target = Util.get_player()
	status_effect.track_name = target.last_damage_source
	status_effect.rounds = 1
	manager.add_status_effect(status_effect)




func get_status_name() -> String:
	return "Cursed Foreman"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/cog_sad.png")
