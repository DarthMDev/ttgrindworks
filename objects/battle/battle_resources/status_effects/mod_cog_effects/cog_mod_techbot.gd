@tool
extends StatusEffect

var rounds_alive = 0
var showing = false
var justin_bieber = preload("res://objects/battle/battle_resources/cog_attacks/resources/justin_bieber.tres")

func apply() -> void:
	var cog: Cog = target
	cog.techbot = true
	manager.s_gags_chosen.connect(on_gags_chosen)

func renew() -> void:
	if rounds_alive == 0:
		manager.battle_ui.justin_bieber()
		showing = true
	elif rounds_alive == 1:
		manager.battle_ui.hide_attack_label()
		showing = false
	rounds_alive+=1

func on_gags_chosen(actions: Array[ToonAttack]) -> void:
	if showing:
		var sound_immunity = justin_bieber.duplicate()
		sound_immunity.user = target
		sound_immunity.targets = [target]
		manager.append_action(sound_immunity)
		sound_immunity.rounds = 1

func get_status_name() -> String:
	return "Archaic Techbot"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/techbot.png")

func cleanup() -> void:
	manager.s_gags_chosen.disconnect(on_gags_chosen)
	if showing:
		showing = false
		manager.battle_ui.hide_attack_label()
		
