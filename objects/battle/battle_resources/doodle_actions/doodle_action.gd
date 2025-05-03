extends ActionScript
class_name DoodleAction

const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")


## Makes doodle walk to toonup position
func begin_trick():
	# Get relevant info
	var action_pos : Vector3 = manager.battle_node.get_relative_position(Vector3(0,0,2))
	var walk_time := 1.0
	var target_pos : Vector3 = targets[0].global_position
	
	# Animate walking
	set_camera_angle('TOON_FOCUS')
	user.set_animation('walk')
	var walk_tween : Tween = user.create_tween()
	walk_tween.tween_property(user,'global_position',action_pos,walk_time)
	await walk_tween.finished
	walk_tween.kill()
	user.set_animation('neutral')
	user.face_position(target_pos)

func end_trick():
	# Get relevant info
	var end_pos : Vector3 = manager.battle_node.get_partner_position(Util.get_player().partners.find(user))
	var walk_time := 1.0
	var battle_pos : Vector3 = manager.battle_node.global_position
	
	# Animate walking
	set_camera_angle('TOON_FOCUS')
	user.set_animation('walk')
	user.face_position(end_pos)
	var walk_tween : Tween = user.create_tween()
	walk_tween.tween_property(user,'global_position',end_pos,walk_time)
	await walk_tween.finished
	walk_tween.kill()
	user.set_animation('neutral')
	user.face_position(battle_pos)

func create_stat_boost(stat : String, boost : float, rounds := 1) -> StatBoost:
	var new_boost := STAT_BOOST_REFERENCE.duplicate()
	
	new_boost.quality = StatusEffect.EffectQuality.POSITIVE
	
	new_boost.stat = stat
	new_boost.boost = boost
	new_boost.rounds = rounds
	new_boost.target = Util.get_player()
	
	return new_boost
