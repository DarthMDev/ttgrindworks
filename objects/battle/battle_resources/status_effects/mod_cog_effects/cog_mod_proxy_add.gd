
@tool
extends StatusEffect

#const Add_Proxy_Attack := preload("res://objects/battle/battle_resources/cog_attacks/resources/proxy+.tres") # or whatever I rename it 
#var Add_Proxy_Attack := preload("res://objects/battle/battle_resources/cog_attacks/resources/proxy_attack.tres")
#var Add_Proxy_Attack := preload("res://objects/battle/battle_resources/cog_attacks/resources/proxy_attack.tres")	
var Add_Proxy_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/suffering_attack.tres")
const CALCULATOR := preload('res://models/props/cog_props/calculator/calculator.glb')

var cog: Cog

func apply() -> void:
	cog = target
	if Util.final_boss:
		var proxy_attack: = Add_Proxy_Attack.duplicate()
		proxy_attack.user = cog
		proxy_attack.targets = [cog]
		manager.append_action(proxy_attack)
	#var proxy_attack: = Add_Proxy_Attack.duplicate()
	#print(proxy_attack)
	#proxy_attack.user = cog
	#print(proxy_attack.user)
	#manager.round_end_actions.append(proxy_attack) 
	
func renew() -> void:
	var cog = target
	var proxy_attack: = Add_Proxy_Attack.duplicate()
	proxy_attack.user = cog
	proxy_attack.targets = [cog]
	manager.round_end_actions.append(proxy_attack) 
	

func get_icon() -> Texture2D:
	return load("res://ui_assets/achievements/icon_achievement_boss_gear4.png") #change the icon color red

func get_status_name() -> String:
	return "Annoying Foreman"
