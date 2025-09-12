@tool
extends StatusEffect

var Snipe_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/snipe.tres")


var cog: Cog
var player: Player
var fire: GPUParticles3D
var damage := 0
var applied := false
var unstable = false


func apply() -> void:
	player = Util.get_player()
	manager.s_status_effect_added.connect(on_status_added)
	manager.s_participant_died.connect(taunt)



func renew() -> void:
	return
	


func on_status_added(status : StatusEffect) -> void:
	if unstable:
		if manager.sniper_cringe:
			return
	if status.target == player and status.quality == 1:
		var attack = Snipe_Attack.duplicate()
		attack.damage = target.level * 0.5  # change later to account for battle stats
		attack.user = target
		attack.targets = [player]
		attack.custom_player_death_source = "A devious Quick scope"
		manager.inject_battle_action(attack, 0)
		#if not manager.sniper_cringe:
		#	manager.inject_battle_action(attack, 0)
		#else:
		#	manager.inject_battle_action(attack, 0)
			#manager.round_end_actions.append(attack)


func cleanup() -> void:
	if manager.s_status_effect_added.is_connected(on_status_added):
		manager.s_status_effect_added.disconnect(on_status_added)
	manager.s_participant_died.disconnect(taunt)
func taunt(who) -> void:
	if who == player:
		target.set_animation('song-and-dance')
func get_icon() -> Texture2D:
	return load("res://ui_assets/battle/statuses/sniper.png")
