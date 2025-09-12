
@tool
extends StatusEffect

	
var Rush_Job_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/rush_job.tres")
const STAT_BOOST := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
var cog: Cog
var unstable = false

func apply() -> void:
	cog = target
	if Util.final_boss2:
			var rush_job: = Rush_Job_Attack.duplicate()
			rush_job.user = cog
			rush_job.targets = [cog]
			manager.append_action(rush_job) 
	
func renew() -> void:
	var cog = target
	var rush_job: = Rush_Job_Attack.duplicate()
	rush_job.user = cog
	rush_job.targets = [cog]
	manager.round_end_actions.append(rush_job) 
	

func get_icon() -> Texture2D:
	return load("res://ui_assets/misc/arrow_red.png") #change the icon color red

func get_status_name() -> String:
	return "Laborious"
