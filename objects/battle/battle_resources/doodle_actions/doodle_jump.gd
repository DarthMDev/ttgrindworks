extends DoodleAction
class_name DoodleJump

## Amount to heal player
const HEAL_PERCENT := 0.1


func action():
	# Setup
	var target = targets[0] # Player
	var doodle : Doodle = user.doodle
	var jump_time := 1.0
	
	# Begin (await an additional half second for pacing)
	await begin_trick()
	await manager.sleep(0.5)
	
	# Animate jump w/ sfx
	user.set_animation('jump')
	AudioManager.play_sound(load('res://audio/sfx/doodle/jump.ogg'))
	
	# Create a tween that moves the doodle body up and down
	await manager.sleep(0.18)
	var jump_tween : Tween = user.create_tween()
	jump_tween.set_trans(Tween.TRANS_QUART)
	jump_tween.set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(doodle,'position:y',1.0,jump_time/2.0)
	jump_tween.set_ease(Tween.EASE_IN)
	jump_tween.tween_property(doodle,'position:y',0.0,jump_time/2.0)
	
	await jump_tween.finished
	
	# Affect the target
	var heal_amount : int = -ceil(target.stats.max_hp * HEAL_PERCENT)
	manager.s_focus_char.emit(target)
	target.toon.speak('Ha Ha Ha')
	manager.affect_target(target, heal_amount)
	target.set_animation('happy')
	await target.animator.animation_finished
	
	# End
	await end_trick()
