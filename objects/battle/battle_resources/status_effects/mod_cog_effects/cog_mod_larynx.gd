@tool
extends StatusEffect
var Bellow_Reference = preload("res://objects/battle/battle_resources/cog_attacks/resources/bellow.tres")

func apply() -> void:
	var cog: Cog = target
	if Util.final_boss:
		var bellow_attack: = Bellow_Reference.duplicate()
		bellow_attack.user = target
		bellow_attack.targets = [target]
		manager.append_action(bellow_attack)
		Task.delay(0.05)
	cog.stats.damage *= 1
	#var bellow_attack: = Bellow_Reference.duplicate()
	#bellow_attack.user = cog
	#manager.round_end_actions.append(bellow_attack)
	manager.s_actions_ended.connect(on_actions_end)

func on_actions_end() -> void:
	return
	#("SHOULD NOT BE RAN RIGHT NOW larynx")
	var iterator = 0
	var status_effects = manager.status_effects.duplicate()
	for status_effect: StatusEffect in status_effects:
		if status_effect.target is Cog and status_effect.quality == 1:
			await manager.expire_status_effect(status_effect)

func cleanup() -> void:
	manager.s_actions_ended.disconnect(on_actions_end)
func renew() -> void:
	var bellow_attack: = Bellow_Reference.duplicate()
	bellow_attack.user = target
	bellow_attack.targets = [target]
	manager.append_end_action(bellow_attack)
	Task.delay(0.05)

	

func get_status_name() -> String:
	return "Larynx"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/larynx.png")
