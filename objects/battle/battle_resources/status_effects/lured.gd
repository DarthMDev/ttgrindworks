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
		var stats : BattleStats = manager.battle_stats[cog]
		stats.damage *= damage_nerf

func get_description() -> String:
	var return_string := "Knockback Damage: %d" % get_true_knockback()
	if lure_type == LureType.DAMAGE_DOWN:
		return_string += "\n-%d%% Damage" % roundi(abs(damage_nerf - 1.0) * 100)
	return return_string

func expire() -> void:
	target.lured = false
	var walk_tween := create_walk_tween()
	await walk_tween.finished
	walk_tween.kill()
	if lure_type == LureType.DAMAGE_DOWN:
		manager.battle_stats[target].damage *= (1 / damage_nerf)
	else:
		target.stunned = false
		manager.unskip_turn(target)
		await manager.run_actions()

func get_true_knockback() -> int:
	var stats := Util.get_player().stats
	return roundi(knockback_effect * stats.get_stat('damage') * stats.gag_effectiveness['Lure'])

func create_walk_tween() -> Tween:
	var cog: Cog = target
	var battle_node := manager.battle_node
	
	var walk_tween := manager.create_tween()
	walk_tween.tween_callback(cog.set_animation.bind('walk'))
	walk_tween.tween_callback(battle_node.focus_character.bind(cog))
	walk_tween.tween_property(cog.get_node('Body'), 'position:z', 0.0, 0.5)
	walk_tween.tween_callback(cog.set_animation.bind('neutral'))
	
	return walk_tween

func get_effect_string() -> String:
	match lure_type:
		LureType.STUN: return 'Stun'
		_: return 'Damage Down'

func get_status_name() -> String:
	return "Lured"
