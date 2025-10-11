@tool
extends StatusEffect
class_name UnionBusterLogic

@export var contract_limit_cooldown: int = 2
var contract_limit_time: int

@export var liability_waiver_cooldown: int = 2
var liability_waiver_time: int

var contract_limit_attack: CogAttack = preload("res://objects/battle/battle_resources/misc_movies/union_buster/contract_limit.tres")
var liability_waiver_attack: CogAttack = preload("res://objects/battle/battle_resources/misc_movies/union_buster/liability_waiver.tres")

var union_buster: Cog

# Called by battle manager on initial application
func apply():
	rounds = -1

	manager.s_round_started.connect(try_liability_waiver)
	manager.s_round_started.connect(try_contract_limit)
	
	contract_limit_time = 0
	liability_waiver_time = 0
	
	union_buster = target

func cleanup() -> void:
	if manager.s_round_started.is_connected(try_contract_limit):
		manager.s_round_started.disconnect(try_contract_limit)
		
	if manager.s_round_started.is_connected(try_liability_waiver):
		manager.s_round_started.disconnect(try_liability_waiver)

func try_contract_limit(_actions):
	# We don't want to decrease the cooldown while contract limit is active
	if check_for_contract_limit():
		return
	# Now we want to decrease it
	if contract_limit_time > 0:
		contract_limit_time -= 1
		return
	
	var attack: CogAttack = contract_limit_attack.duplicate(true)
	
	attack.user = union_buster
	
	var possible_targets: Array = union_buster.get_targets(attack.target_type).duplicate(true)
	# Filter out directors from this pool of targets
	possible_targets = possible_targets.filter(func(x: Cog): return x.dna.custom_nametag_suffix != 'Director')
	
	# Oh no! No targets. guess we suck.
	if len(possible_targets) == 0:
		return
	
	var highest_level_cog = possible_targets[0]
	# Pick out the highest level Cog in our roster
	for i in range(1,possible_targets.size()):
		var current_cog = possible_targets[i]
		if highest_level_cog.level < current_cog.level:
			highest_level_cog = current_cog
	
	attack.targets = [highest_level_cog]
	
	manager.round_end_actions.append(attack)
	contract_limit_time = contract_limit_cooldown

func check_for_contract_limit():
	for cog in manager.cogs:
		var status_effects = manager.get_statuses_for_target(cog)
		
		for effect in status_effects:
			if effect is UBContractLimitBomb:
				return true
	
	return false
	
func try_liability_waiver(_actions):
	# We don't want to decrease the cooldown while liability waiver is active
	if check_for_liability_waiver():
		return
	# Now we want to decrease it
	if liability_waiver_time > 0:
		liability_waiver_time -= 1
		return
	
	var attack: CogAttack = liability_waiver_attack.duplicate(true)
	
	var possible_targets: Array = union_buster.get_targets(attack.target_type).duplicate(true)
	
	# Filter out directors from this pool of targets
	possible_targets = possible_targets.filter(func(x: Cog): return x.dna.custom_nametag_suffix != 'Director')
	
	# Oops! No targets.
	if len(possible_targets) == 0:
		return
	
	attack.user = union_buster
	
	var lowest_level_cog = possible_targets[0]
	# Pick out the lowest level Cog in our roster
	for i in range(1,possible_targets.size()):
		var current_cog = possible_targets[i]
		if lowest_level_cog.level > current_cog.level:
			lowest_level_cog = current_cog
	
	attack.targets = [lowest_level_cog]
	
	manager.round_end_actions.append(attack)
	liability_waiver_time = liability_waiver_cooldown

	
func check_for_liability_waiver():
	for cog in manager.cogs:
		var status_effects = manager.get_statuses_for_target(cog)
		
		for effect in status_effects:
			if effect is UBLiabilityWaiverEffect:
				return true
	
	return false
