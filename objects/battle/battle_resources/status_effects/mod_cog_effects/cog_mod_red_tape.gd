@tool
extends StatusEffect
const Curse_Status_Reference := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_bind.tres")
var Red_Tape_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/red_tape_attack.tres")
#var Red_Tape_Attack2 = preload("res://objects/battle/battle_resources/cog_attacks/resources/red_tape_attack.tres")

func apply() -> void:
	#var status_effect := Curse_Status_Reference.duplicate()
	#status_effect.target = Util.get_player()
	#status_effect.rounds = 0
	#manager.add_status_effect(status_effect)
	pass

	

func on_death() -> void:
	pass

func renew() -> void:
	#var status_effect := Curse_Status_Reference.duplicate()
	#status_effect.target = Util.get_player()
	#status_effect.rounds = 0
	#manager.add_status_effect(status_effect)
	var cog = target
	var red_tape: =  load('res://objects/battle/battle_resources/cog_attacks/resources/red_tape_attack.tres').duplicate()
	red_tape.user = target
	red_tape.damage = 2
	red_tape.targets = [Util.get_player()]
	#print(red_tape.targets[0])
	manager.round_end_actions.append(red_tape) 
	
	

	


func get_status_name() -> String:
	return "Red Tape"

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/red_tape.png")
