extends CogAttack

@export var status_effect: UBContractLimitBomb

var SFX := preload("res://audio/sfx/battle/cogs/attacks/special/contractlimit_audio.ogg")

func action() -> void:
	# Get target Cog
	if targets.is_empty():
		return
	
	var target_cog: Cog = targets[0]
	# Focus Cog
	user.set_animation('times-up')
	battle_node.focus_character(user)
	AudioManager.play_sound(SFX, 7.0)
	
	await manager.sleep(3.0)
	
	# Focus the Cog
	battle_node.focus_character(target_cog)
	
	# Apply the status effect
	var stat_effect: UBContractLimitBomb = status_effect.duplicate(true)
	stat_effect.target = target_cog
	stat_effect.union_buster = user
	manager.add_status_effect(stat_effect)
	
	await manager.sleep(4.5)
