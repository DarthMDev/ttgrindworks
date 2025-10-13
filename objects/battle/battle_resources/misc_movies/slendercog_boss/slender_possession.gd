extends ActionScript
class_name SlenderPossession

## Associated constants
const SLENDER_DNA := preload('res://objects/cog/presets/misc/slender_cog.tres')
const ACTION_NAME := "Possession"
const ACTION_SUMMARY := "Slendercog possesses one of his vessels!"
const HOLE_SCENE := preload('res://objects/misc/teleport_hole/teleport_hole.tscn')
var should_increase := true


func action() -> void:
	# Find the Cog who will be possessed
	var possessed : Cog
	# Find the Cog with the highest remaining HP
	for cog in manager.cogs:
		if not possessed or possessed.stats.hp < cog.stats.hp:
			possessed = cog
	
	if not possessed:
		return
	
	# Update the directory's slendercog reference
	user.slendercog = possessed
	
	# Create the hole under the Cog
	var hole := HOLE_SCENE.instantiate()
	var hole_animator : AnimationPlayer = hole.get_node('AnimationPlayer')
	possessed.add_child(hole)
	hole.position.y += 0.05
	hole.hide()
	
	# Start movie
	var action_tween := manager.create_tween()
	
	# Focus Cog
	action_tween.tween_callback(manager.show_action_name.bind(ACTION_NAME,ACTION_SUMMARY))
	action_tween.tween_callback(battle_node.focus_character.bind(possessed))
	
	# If Cog is lured, unlure it
	if possessed.lured:
		action_tween.tween_callback(manager.force_unlure.bind(possessed))
		action_tween.tween_callback(possessed.set_animation.bind('walk'))
		action_tween.tween_property(possessed.get_node('Body'),'position:z',0.0, 1.0)
		action_tween.tween_callback(possessed.set_animation.bind('neutral'))
	
	# Cog Falls into hole
	action_tween.tween_callback(hole.show)
	action_tween.tween_callback(hole_animator.play.bind('grow'))
	action_tween.tween_interval(0.5)
	action_tween.tween_callback(possessed.set_animation.bind('flailing'))
	action_tween.tween_interval(1.25)
	
	# Cog falls into hole
	action_tween.tween_property(possessed.body_root,'position:y',-10.0,1.0)
	action_tween.tween_interval(1.0)
	
	# Replace Cog's DNA with slendercog dna
	action_tween.tween_callback(possess.bind(possessed))
	action_tween.tween_callback(possessed.battle_start)
	
	# Have slendercog fly back in
	action_tween.tween_callback(possessed.set_animation.bind('landing'))
	action_tween.tween_callback(possessed.animator_seek.bind(0.1))
	action_tween.tween_callback(possessed.pause_animator)
	action_tween.set_trans(Tween.TRANS_QUAD)
	action_tween.tween_property(possessed.body_root,'position:y',0.0,3.0)
	action_tween.tween_callback(possessed.unpause_animator)
	action_tween.tween_callback(hole_animator.play.bind('shrink'))
	action_tween.tween_interval(4.0)
	await action_tween.finished
	
	# Clean up
	action_tween.kill()
	hole.queue_free()

## Swaps the Cog with Slendercog's DNA
## And does some setup
func possess(cog : Cog) -> void:
	cog.set_dna(SLENDER_DNA,false)
	for effect in SLENDER_DNA.instantiate_status_effects():
		effect.target = cog
		manager.add_status_effect(effect)
	if should_increase:
		manager.unskip_turn(cog)
