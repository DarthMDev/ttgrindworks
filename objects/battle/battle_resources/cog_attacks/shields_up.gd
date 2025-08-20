extends CogAttack
class_name Shieldup

#const SFX := preload("res://audio/sfx/battle/cogs/SA_bellow.ogg")

@export var play_sound := true
var rage = true

func action() -> void:
	
	# Focus Cog
	if rage:
		user.set_animation('jump')
	else: user.set_animation('buffed')
	battle_node.focus_character(user)
	await manager.sleep(3.5)
