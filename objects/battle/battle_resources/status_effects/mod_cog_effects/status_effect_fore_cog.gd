@tool
extends StatusEffect


const MOD_EFFECTS : Array[StatusEffect] = [ #res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_drop_immunity.tres
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_techbot.tres"), #0
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_disguise.tres"), #1
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_proxy_add.tres"),
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_drop_immunity.tres"), #3
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_rebalance.tres"), #4
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_lure_immunity.tres"), #5
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_troll.tres"),
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_damage_drift.tres"), #7
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_larynx.tres"), #8
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_beneficiary.tres"), #9
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_v15_foreman.tres"), #10
	preload("res://objects/battle/battle_resources/misc_movies/traffic_manager/mod_cog_green_light.tres"), #11
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_cursed_foreman.tres"), #12
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sheer_force.tres"), #13 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_thorns.tres"), #14 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_alphabet.tres"), #15 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_red_tape.tres"), #16
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_laborious.tres"), #17 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_spongy.tres"), #18
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_ruins.tres"), #19
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_whistleblower_fan.tres"), #20 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_litigant.tres"), #21
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_cohesive.tres"), #22
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_sniper.tres"), #23 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_bookkeeper_fan.tres"), #24 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_hp_guy.tres"), #25 s
	preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_confused.tres"), #26 s
	
	
	
	
	


]

var overcharged = preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_overcharged.tres")
const RESTRICTED_EFFECT_INDEXES := [0, 3, 5, 6, 9]  # techbot, drop_immunity, lure_immunity, troll, beneficiary for chartist pool in future
const PENTHOUSE_FOREMAN_INDEXES := [2, 7, 8, 9]  # proxy+,damage_drift, larynx, beneficiary for boss pool
const PENTHOUSE2_FOREMAN_INDEXES := [13,15,16,17,22]  # sheer+,alphabet,tape , laborious, cohesive for boss pool
var force = false
var cheat_index = -1
var use_strong_cheat = false
var weak_cheat_end_index = 12
var strong_cheat_end_index = 26 
func apply() -> void:
	
		var mod_effect
		if cheat_index == -1:
			print("no cheat index naaau")
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
				index = 26
			elif Globals.fore_cog_index == 1:
				index = 26 #11
			elif Globals.fore_cog_index == 2:
				index = 23 #6
			else:
				index = 26
			return index
func choose_random_cheat() -> StatusEffect:
	var mod_effect : StatusEffect
	Globals.fore_cog_index += 1
	if Util.final_boss:
		print("util fnl boss 1")
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
		print("util fnl boss 222")
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
			while mod_effect.get_status_name() in Globals.last_fore_abilities:
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

	
