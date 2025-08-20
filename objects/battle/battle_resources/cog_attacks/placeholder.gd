extends CogAttack
class_name Placeholder

#const SFX := preload("res://audio/sfx/battle/cogs/SA_bellow.ogg")

@export var play_sound := true
var magic = false
var play_anim = true
var battle_txt = false
var battle_txt_string = ""

func action() -> void:
	
	# Focus Cog
	if play_anim:  user.set_animation('effort')
	battle_node.focus_character(user)
	var iterator = 0
	if battle_txt:
		manager.battle_text(user,battle_txt_string)
	await manager.sleep(3.5)
