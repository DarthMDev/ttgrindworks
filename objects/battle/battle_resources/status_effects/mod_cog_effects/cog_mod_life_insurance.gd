
@tool
extends StatusEffect

var Insurance_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/insurance.tres")

var cog: Cog

func apply() -> void:
	cog = target
	
func renew() -> void:
	var cog = target
	if target.stats.hp < target.stats.max_hp and manager.cogs.size() > 1:
		var proxy_attack: = Insurance_Attack.duplicate()
		proxy_attack.user = cog
		proxy_attack.targets = [cog]
		manager.round_end_actions.append(proxy_attack)
	

func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/proxy_add.png") #change the icon color red

func get_status_name() -> String:
	return "Life Insurance"
