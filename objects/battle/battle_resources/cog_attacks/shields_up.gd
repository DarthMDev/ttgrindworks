extends CogAttack
class_name Shieldup

const SFX1 := preload("res://audio/sfx/battle/cogs/SA_rage.ogg")
const SFX2 := preload("res://audio/sfx/battle/cogs/SA_defense.ogg")
@export var play_sound := true
var rage = true


func action() -> void:
	
	# Focus Cog
	if rage:
		user.set_animation('jump')
		if play_sound:  AudioManager.play_sound(SFX1)
	else: 
		user.set_animation('buffed')
		if play_sound:  AudioManager.play_sound(SFX2)
	battle_node.focus_character(user)
	await manager.sleep(3.5)
