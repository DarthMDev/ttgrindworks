@tool
extends StatusEffect
class_name StatEffectRegeneration

const COG_REGEN_EFFECT := preload("res://objects/battle/effects/cog_healing/cog_healing.tscn")
const COG_HEAL_PHRASES : Array[String] = [
	"Time to exercise my right to repair.",
	"You can't keep up with these gains.",
	"I hope this doesn't void my warranty."
]

@export var amount : int
@export var instant_effect := true


func apply():
	if instant_effect:
		manager.affect_target(target, -amount)

func renew():
	if target.stats.hp == target.stats.max_hp:
		return
	manager.s_focus_char.emit(target)
	manager.affect_target(target, -amount)
	if target is Player:
		target.toon.speak('Ha Ha Ha')
		target.set_animation('happy')
		await manager.barrier(target.animator.animation_finished, 4.0)
		target.set_animation('neutral')
	elif target is Cog:
		target.set_animation('buffed')
		target.speak(RandomService.array_pick_random('true_random', COG_HEAL_PHRASES))
		do_cog_regen_tween(target)
		await manager.barrier(target.animator.animation_finished, 4.0)

func get_description() -> String:
	if target is Player:
		return "+%s Laff regeneration" % amount
	return "+%s HP regeneration" % amount

func get_status_name() -> String:
	if status_name == "Status Effect":
		return "Regeneration"
	return status_name

func randomize_effect() -> void:
	rounds = RandomService.randi_range_channel('true_random', 1, 3)
	if target:
		amount = ceili(RandomService.randf_range_channel('true_random', ceili(target.stats.max_hp * 0.1), ceili(target.stats.max_hp * 0.25)))
	else:
		amount = RandomService.randi_range_channel('true_random', 1, 10)

func do_cog_regen_tween(cog : Cog) -> void:
	var particle : Node3D = COG_REGEN_EFFECT.instantiate()
	particle.scale *= 0.01
	particle.position.y = 0.05
	cog.body_root.add_child(particle)
	var tween := manager.create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(particle, 'scale', Vector3.ONE * cog.dna.scale, 0.5)
	tween.tween_interval(1.5)
	tween.tween_property(particle, 'scale', Vector3.ONE * 0.01, 0.5)
	tween.tween_callback(particle.queue_free)
	tween.finished.connect(tween.kill)

func combine(effect : StatusEffect) -> bool:
	if effect is StatEffectRegeneration and effect.rounds == rounds:
		amount += effect.amount
		return true
	return false
	
