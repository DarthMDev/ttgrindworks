extends CogAttack
class_name Bellow

const SFX := preload("res://audio/sfx/battle/cogs/SA_bellow.ogg")

@export var play_sound := true

func action() -> void:
	manager.bellow = true
	# Get player
	if play_sound:
		AudioManager.play_sound(SFX)
	
	# Focus Cog
	user.set_animation('effort')
	battle_node.focus_character(user)
	var iterator = 0
	var particles = load('res://objects/battle/effects/soundwave/directed.tscn').instantiate()
	user.add_child(particles)
	particles.global_position = user.body.head_node.global_position + Vector3(0, -0.4, 0)



	var player_pos = Util.get_player().head_node.global_position
	var particle_dir = particles.global_position.direction_to(player_pos)

	
	await manager.sleep(4.0)
	var status_effects = manager.status_effects.duplicate()
	for status_effect: StatusEffect in status_effects:
		if status_effect.target is Cog and status_effect.quality == 1:
			await manager.expire_status_effect(status_effect)
			await manager.sleep(0.7)
	particles.emitting = false		
	await manager.sleep(0.5)
	
	
	particles.queue_free()
	manager.bellow = false
