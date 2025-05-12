extends CogAttack
class_name SlenderStaticIncrease

const ALPHA_GOAL := 0.5
const ALPHA_INCREMENT := 0.05
const SFX_INCREASE := preload('res://audio/sfx/battle/cogs/misc/page7.ogg')

@export var additional_attacks : Array[CogAttack]

var slendercog_directory : Node3D

func action() -> void:
	if not slendercog_directory:
		return
	
	# Create a tween that increases the tv static's alpha
	var noise_tex : TextureRect = slendercog_directory.tv_static
	var alpha_current : float = noise_tex.get_alpha()
	var player := Util.get_player()
	player.last_damage_source = "Slender Sickness"
	
	# Movie Start
	var action_tween := manager.create_tween()
	
	# Increment the alpha if it's below the goal
	if alpha_current < ALPHA_GOAL and not is_equal_approx(alpha_current, ALPHA_GOAL):
		# Focus user
		action_tween.tween_callback(battle_node.focus_character.bind(user))
		action_tween.tween_callback(user.set_animation.bind('effort'))
		action_tween.tween_callback(
		func():
			var audio_player := AudioManager.play_sound(SFX_INCREASE)
			audio_player.pitch_scale = 0.7
			audio_player.volume_db = 4.0
		)
		action_tween.tween_interval(1.0)
		
		# Increase the alpha
		action_tween.set_trans(Tween.TRANS_QUAD)
		action_tween.tween_method(noise_tex.set_alpha, alpha_current, alpha_current + ALPHA_INCREMENT, 1.0)
		action_tween.tween_callback(slendercog_directory.increment_ambience)
		action_tween.tween_interval(2.0)
	
	# Focus Player and do damage
	action_tween.tween_callback(battle_node.focus_character.bind(player))
	action_tween.tween_callback(player.set_animation.bind('cringe'))
	action_tween.tween_callback(manager.affect_target.bind(player, get_scaled_damage(alpha_current + ALPHA_INCREMENT)))
	action_tween.tween_interval(3.0)
	
	await action_tween.finished
	action_tween.kill()
	
	await manager.check_pulses(targets)

func get_scaled_damage(alpha : float) -> int:
	return floori(damage * minf(1.0, (alpha / ALPHA_GOAL)))

func get_additional_attack() -> CogAttack:
	if additional_attacks.is_empty():
		return null
	var attack : CogAttack = additional_attacks[RandomService.randi_channel('true_random') % additional_attacks.size()].duplicate()
	attack.targets = [Util.get_player()]
	attack.damage += user.get_damage_boost()
	attack.user = user
	return attack
