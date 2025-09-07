
@tool
extends StatusEffect


var reinfocement_attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/lawyer_call.tres")
var bust = preload("res://objects/battle/battle_resources/misc_movies/union_buster/contract_limit2.tres")
var summoned = false
var cog: Cog
var fodder: Cog
var busted = false
var summon_cooldown = 0

func apply() -> void:
	cog = target
	summon_cooldown = 0
	summoned = false
	manager.s_participant_joined.connect(participant_joined)
	manager.s_round_started.connect(on_round_start)

func on_round_start(actions : Array[BattleAction]) -> void:
	if summoned and not busted:
		var inject_pos := 0
		for i in actions.size():
			if actions[i] is ToonAttack or actions[i] is CogAttack:
				inject_pos = i
				break
		var action = bust.duplicate()
		action.user = target
		action.targets = [fodder]
		manager.round_actions.insert(inject_pos, action)
		busted = true
		summoned = false
		summon_cooldown = 2
	


	
func renew() -> void:
	if not summoned:
		if summon_cooldown > 0:
			summon_cooldown = 0
			return
		var lawyer_summon = reinfocement_attack
		reinfocement_attack.cog_amount = 1
		#reinfocement_attack.attack_lines = ["This is Outrageous I am going to sue"]
		reinfocement_attack.user = cog
		reinfocement_attack.targets = [cog]
		manager.round_end_actions.append(reinfocement_attack) 

func participant_joined(who: Node3D) -> void:
	if not summoned:
		if who is Cog:
			if who.dna.cog_name == "Lawyer Poser":
				fodder = who
				summoned = true
				busted = false
		#apply_to_cog(who)	
func cleanup() -> void:
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	if manager.s_round_started.is_connected(on_round_start):
		manager.s_round_started.disconnect(on_round_start)

func get_icon() -> Texture2D:
	return load("res://models/props/facility_objects/da_office/filing_cabinet_open/filing_cabinet_open.fbm/LB_paper_stacks.png") #change the icon color red

func get_status_name() -> String:
	return "Suehappy"
