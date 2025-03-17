@tool
extends StatusEffect
class_name StatEffectRegeneration

@export var amount : int
@export var instant_effect := true

func apply():
	if instant_effect:
		manager.affect_target(target, -amount)

func renew():
	manager.s_focus_char.emit(target)
	manager.affect_target(target, -amount)
	if target is Player:
		target.toon.speak('Ha Ha Ha')
		target.set_animation('happy')
		await target.animator.animation_finished
		target.set_animation('neutral')
