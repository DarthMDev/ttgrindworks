extends CogAttack
class_name UBContractLimitb

#var contract_limit_attack: UBContractLimit = preload("res://objects/battle/battle_resources/misc_movies/union_buster/contract_limit.tres")
@export var status_effect: ForemanContractLimitBomb

var SFX := preload("res://audio/sfx/battle/cogs/attacks/special/contractlimit_audio.ogg")

func action() -> void:
	# Get target Cog
	if targets.is_empty():
		return
	
	var target_cog: Cog = targets[0]
	# Focus Cog
	user.set_animation('times-up')
	battle_node.focus_character(user)
	#AudioManager.play_sound(SFX, 7.0)
	
	await manager.sleep(3.0)
	
	# Focus the Cog
	battle_node.focus_character(target_cog)
	
	# Apply the status effect
	var stat_effect: ForemanContractLimitBomb = status_effect.duplicate()
	stat_effect.target = target_cog
	stat_effect.union_buster = user
	stat_effect.rounds = 0
	manager.add_status_effect(stat_effect)
	
	await manager.sleep(4.5)
