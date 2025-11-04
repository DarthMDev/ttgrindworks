@tool
extends StatusEffect
class_name StatusLured

enum LureType {
	STUN,
	DAMAGE_DOWN
}

@export var lure_type := LureType.STUN
@export var knockback_effect := 10
@export var damage_nerf := 0.5

func apply() -> void:
	var cog: Cog = target
	cog.lured = true
	cog.get_node('Body').position.z = Globals.SUIT_LURE_DISTANCE
	if lure_type == LureType.STUN:
		manager.skip_turn(cog)
		cog.stunned = true
	else:
		var stats: BattleStats = manager.battle_stats[cog]
		stats.damage += damage_nerf
		stats.accuracy += damage_nerf / 2.0

func get_description() -> String:
	var return_string := "Knockback Damage: %d" % get_true_knockback()
	if lure_type == LureType.DAMAGE_DOWN:
		var dmg_nerf: String = str(roundi(damage_nerf * 100.0))
		var acc_nerf: String = str(roundi((damage_nerf / 2.0) * 100.0))
		return_string += "\n%s%% Damage\n%s%% Accuracy" % [dmg_nerf, acc_nerf]
	return return_string

func expire() -> void:
	target.lured = false
	var walk_tween := create_walk_tween()
	await walk_tween.finished
	walk_tween.kill()
	if lure_type == LureType.DAMAGE_DOWN:
		manager.battle_stats[target].damage -= damage_nerf
		manager.battle_stats[target].accuracy -= damage_nerf / 2.0
	else:
		target.stunned = false
		manager.unskip_turn(target)
		await manager.run_actions()

func get_true_knockback() -> int:
	var stats := Util.get_player().stats
	return roundi(knockback_effect * stats.get_stat('damage') * stats.get_track_effectiveness('Lure'))

func create_walk_tween() -> Tween:
	var cog: Cog = target
	var battle_node := manager.battle_node
	
	var walk_tween := manager.create_tween()
	walk_tween.tween_callback(cog.set_animation.bind('walk'))
	walk_tween.tween_callback(battle_node.focus_character.bind(cog))
	walk_tween.tween_callback(cog.animator.set_speed_scale.bind(-1.0))
	walk_tween.tween_property(cog.get_node('Body'), 'position:z', 0.0, 0.5)
	walk_tween.tween_callback(cog.set_animation.bind('neutral'))
	walk_tween.tween_callback(cog.animator.set_speed_scale.bind(1.0))
	return walk_tween

func get_effect_string() -> String:
	match lure_type:
		LureType.STUN: return 'Applies: Stun'
		_: return 'Nerfs: Damage/Accuracy'

func get_status_name() -> String:
	return "Lured"
