extends CogAttack

@export var particle_scene: PackedScene
@export var flash_color: Color = Color.RED
@export var status: StatusEffect

const PARTICLES := preload("res://objects/battle/battle_resources/misc_movies/bookkeeper/mental_math_particles.tscn")

func action():
	user.face_position(Util.get_player().global_position)
	user.set_animation('effort')
	manager.s_focus_char.emit(user)
	
	await manager.sleep(1.0)
	# Start particles
	var particles: Node3D = particle_scene.instantiate()
	user.add_child(particles)
	particles.emitting = true
	user.body.flash(flash_color, 1.0, 0.5)
	apply_effect()
	
	await manager.sleep(2.0)
	particles.emitting = false
	
	await user.animator.animation_finished
	await manager.check_pulses(targets)
	particles.queue_free()

func apply_effect() -> void:
	var effect := status.duplicate(true)
	effect.target = user
	manager.add_status_effect(effect)
