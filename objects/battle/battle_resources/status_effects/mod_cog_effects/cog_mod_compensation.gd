
@tool
extends StatusEffect

	
var Add_Comp_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/foreman_compensation.tres")


var cog: Cog

func apply() -> void:
	cog = target
	cog.stats.is_foreman = true
	if Util.final_boss:
		var comp_attack: = Add_Comp_Attack.duplicate()
		comp_attack.user = cog
		comp_attack.heal_multiplier * 0.5
		comp_attack.targets = [cog]
		manager.append_action(comp_attack)

	
func renew() -> void:
	var cog = target
	var comp_attack: = Add_Comp_Attack.duplicate()
	comp_attack.user = cog
	comp_attack.heal_multiplier * 0.5
	comp_attack.targets = [cog]
	manager.round_end_actions.append(comp_attack) 
	

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/compensation.png")

func get_status_name() -> String:
	return "Compensation"
