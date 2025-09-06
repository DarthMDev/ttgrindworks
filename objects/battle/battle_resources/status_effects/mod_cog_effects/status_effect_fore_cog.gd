@tool
extends StatusEffect


const MOD_EFFECTS : Array[StatusEffect] = [ #res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_drop_immunity.tres
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_techbot.tres"), #0
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_disguise.tres"), #1
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_proxy_add.tres"), #2
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_drop_immunity.tres"), #3
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_rebalance.tres"), #4
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_lure_immunity.tres"), #5
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_troll.tres"), #6
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_damage_drift.tres"), #7
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_larynx.tres"), #8
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_beneficiary.tres"), #9
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_v15_foreman.tres"), #10
	preload("res://objects/battle/battle_resources/misc_movies/traffic_manager/mod_cog_green_light.tres"), #11
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_cursed_foreman.tres"), #12
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_seismic.tres"), #13
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_compensation.tres"), #14
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sheer_force.tres"), #15 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_thorns.tres"), #16 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_alphabet.tres"), #17 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_red_tape.tres"), #18
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_laborious.tres"), #19 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_spongy.tres"), #20
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_ruins.tres"), #21
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_whistleblower_fan.tres"), #22 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_litigant.tres"), #23
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_cohesive.tres"), #24
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sniper.tres"), #25 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_bookkeeper_fan.tres"), #26 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_hp_guy.tres"), #27 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_confused.tres"), #28 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_relentless.tres") # 29
	
	
]

var overcharged = preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_overcharged.tres")
var tenure = preload("res://objects/battle/battle_resources/status_effects/resources/tenure_status.tres")
const CHARTIST_EFFECT_INDEXES := [0, 1, 2, 7, 8, 9, 11]  # techbot, disguise, proxy+, d drift, greenlighter for chartist pool in future
const PENTHOUSE_FOREMAN_INDEXES := [2, 7, 8, 9,13]  # proxy+,damage_drift, larynx, beneficiary for boss pool
const PENTHOUSE2_FOREMAN_INDEXES := [15,17,18,19,24]  # sheer+,alphabet,tape , laborious, cohesive for boss pool
var force = false
var cheat_index = -1
var use_strong_cheat = false
var weak_cheat_end_index = 14
var strong_cheat_end_index = 29 
func apply() -> void:
	
		var mod_effect
		if cheat_index == -1:
			mod_effect = choose_random_cheat()
		#Globals.fore_cog_index += 1
		if Util.survive_the_foreman:
			if mod_effect.get_status_name() == "Green Lighter":
				mod_effect = MOD_EFFECTS[2].duplicate() #proxy+ since 2 seperate green light stuff fail
		mod_effect.target = target
		var forecharge = overcharged.duplicate()
		forecharge.target = target
		manager.add_status_effect(forecharge)
		manager.add_status_effect(mod_effect)
		
func force_cheats() -> int:
			var index
			if Globals.fore_cog_index == 0:
				index = 0
			elif Globals.fore_cog_index == 1:
				index = 18 #11
			elif Globals.fore_cog_index == 2:
				index = 25 #6
			else:
				index = 26
			return index
func choose_random_cheat() -> StatusEffect:
	#This function is awful and pure slop sorryreader
	var mod_effect : StatusEffect
	Globals.fore_cog_index += 1
	#chose certain foreman cheat indexes if final boss
	if Util.final_boss:
		var available_effects = []
		for idx in PENTHOUSE_FOREMAN_INDEXES:
			available_effects.append(MOD_EFFECTS[idx])
		mod_effect = available_effects[RandomService.randi_range_channel('mod_cog_effects', 0, available_effects.size() - 1)]
		var status_name = mod_effect.get_status_name()
		if Globals.last_fore_ability == status_name and not Util.monolitic:
			if status_name != MOD_EFFECTS[8].get_status_name(): # not larynx
				mod_effect = MOD_EFFECTS[8]
			else:
				mod_effect = MOD_EFFECTS[2] # proxy+
		Globals.last_fore_ability = mod_effect.get_status_name()
	elif Util.final_boss2:
		var available_effects = []
		for idx in PENTHOUSE2_FOREMAN_INDEXES:
			available_effects.append(MOD_EFFECTS[idx])
		var max_attempts = 50
		var attempts = 0
		mod_effect = available_effects[RandomService.randi_range_channel('mod_cog_effects', 0, available_effects.size() - 1)]
		while mod_effect.get_status_name() in Globals.last_fore_abilities:
			mod_effect = available_effects[RandomService.randi_range_channel('mod_cog_effects', 0, available_effects.size() - 1)]
			if attempts > max_attempts:
				break
			attempts+= 1
		Globals.last_fore_ability = mod_effect.get_status_name()
	else:
		if Util.floor_number < 6:
			mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', 0, weak_cheat_end_index)]
		else: mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', weak_cheat_end_index + 1, strong_cheat_end_index)]
		if Util.floor_number > 6 and not Util.monolitic:
			var max_attempts = 50
			var attempts = 0
			mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', weak_cheat_end_index + 1, strong_cheat_end_index)]
			if mod_effect.get_status_name() == "Confused":
				mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', weak_cheat_end_index + 1, strong_cheat_end_index)]
			while mod_effect.get_status_name() in Globals.last_fore_abilities:
				mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', weak_cheat_end_index + 1, strong_cheat_end_index)]
				print(Util.floor_number, " is the floor number")
				if Util.floor_number == 7:
					if mod_effect.get_status_name() == "Confused":
						#dont want that weak cheat on floor 7
						mod_effect = MOD_EFFECTS[RandomService.randi_range_channel('mod_cog_effects', weak_cheat_end_index + 1, strong_cheat_end_index)]
				if attempts > max_attempts:
					break
				attempts+= 1
				
		if force: mod_effect =  MOD_EFFECTS[force_cheats()]
		if Util.monolitic: mod_effect = MOD_EFFECTS[Util.force_foreman]
	#index = RandomService.randi_range_channel('mod_cog_effects', 0, MOD_EFFECTS.size() - 1)
	if Util.survive_the_foreman:
		if mod_effect.get_status_name() == "Green Lighter":
			mod_effect = MOD_EFFECTS[2]
	Globals.last_fore_ability = mod_effect.get_status_name()
	var status_name = mod_effect.get_status_name()
	Globals.last_fore_abilities.pop_front()
	Globals.last_fore_abilities.append(status_name)
	return mod_effect
