extends CogAttack
class_name Liquidate

@export var particles : PackedScene
@export var sfx : AudioStream

enum AnimName {
	GLOWER,
	EFFORT,
	MAGIC1
}
@export var animation := AnimName.GLOWER
@export var melt_toon := false

func action():
	# Setup
	var target = targets[0]
	user.face_position(target.global_position)
	var hit := manager.roll_for_accuracy(self)
	manager.s_focus_char.emit(user)
	user.set_animation(str(AnimName.keys()[animation]).to_lower())
	var cloud : Node3D = load('res://models/props/cog_props/cloud/cloud.tscn').instantiate()
	user.add_child(cloud)
	cloud.top_level = true
	cloud.global_position = user.head_node.global_position
	cloud.global_position.y+=1.0
	cloud.scale/=100.0
	
	var puddle : Node3D 
	
	var grow_tween : Tween = cloud.create_tween()
	var destination := Vector3(target.global_position.x,target.head_node.global_position.y+1.0,target.global_position.z)
	grow_tween.tween_property(cloud,'scale',Vector3(1,1,1),1.0)
	grow_tween.tween_interval(0.5)
	grow_tween.tween_property(cloud,'global_position',destination,1.0)
	await grow_tween.finished
	grow_tween.kill()
	
	if sfx:
		AudioManager.play_sound(sfx)
	var particle_effect : Node3D
	if particles: 
		particle_effect = particles.instantiate()
		cloud.add_child(particle_effect)
	
	manager.s_focus_char.emit(target)
	if hit:
		manager.affect_target(target, damage)
		if not melt_toon:
			target.set_animation('duck')
		else:
			puddle = load('res://models/props/gags/quicksand/quicksand.glb').instantiate()
			target.add_child(puddle)
			puddle.position.y = .05
			puddle.scale/=100.0
			var puddle_mesh : MeshInstance3D = puddle.get_node('quicksand/Skeleton3D/TheQuicksand')
			var puddle_mat : StandardMaterial3D = puddle_mesh.mesh.surface_get_material(0).duplicate()
			puddle_mat.albedo_color = Color(0.0,0.0,1.0)
			puddle_mesh.set_surface_override_material(0,puddle_mat)
			target.set_animation('melt')
			var puddle_tween : Tween = puddle.create_tween()
			puddle_tween.tween_property(puddle,'scale',Vector3(0.5,0.5,0.5),0.5)
			await target.animator.animation_finished
			puddle_tween.kill()
			particle_effect.emitting = false
			await manager.sleep(1.0)
			target.set_animation('happy')
			target.animator.seek(0.5)
			var jump_tween : Tween = target.create_tween()
			var toon_y : float = target.toon.position.y
			target.toon.position.y = -1.0
			jump_tween.set_trans(Tween.TRANS_QUAD)
			jump_tween.set_parallel(true)
			jump_tween.tween_property(target.toon,'position:y',toon_y,0.25)
			jump_tween.tween_property(puddle,'scale',Vector3(.01,.01,.01),0.5)
			jump_tween.tween_property(cloud,'scale',Vector3(.01,.01,.01),0.5)
			await jump_tween.finished 
			jump_tween.kill()
	else:
		manager.battle_text(target,"MISSED")
		target.set_animation('sidestep_left')
	await target.animator.animation_finished
	
	cloud.queue_free()
	if puddle:
		puddle.queue_free()
	
	target.set_animation('neutral')
	
	await manager.check_pulses(targets)
