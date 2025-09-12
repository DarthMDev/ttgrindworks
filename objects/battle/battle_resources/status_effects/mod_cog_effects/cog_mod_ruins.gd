@tool
extends StatusEffect

const BOOST_AMOUNT := 0.75
const STAT_BOOST_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
var player_attack = 0
var boost_effects: Array[StatBoost] = []
var cogs_effected = 1

func apply() -> void:
	manager.s_participant_joined.connect(participant_joined)
	manager.s_action_started.connect(on_action_started)
	
	var user: Cog = target
	for cog in manager.cogs:
		if not user == cog:
			apply_to_participant(cog)
	var player: Player = Util.get_player()
	player_attack = player.stats.damage * 0.25 * 1.1
	apply_to_participant(player)

func cleanup() -> void:
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	manager.s_action_started.disconnect(on_action_started)
	end_boost()

func participant_joined(who: Node3D) -> void:
	if who is Cog:
		apply_to_participant(who)

func apply_to_participant(guy) -> void:
	var new_boost := create_boost(guy)
	manager.add_status_effect(new_boost)
	boost_effects.append(new_boost)

func create_boost(who, is_player: bool = false) -> StatBoost:
	var status_effect := STAT_BOOST_RESOURCE.duplicate()
	status_effect.target = who
	status_effect.stat = 'damage'
	status_effect.boost = BOOST_AMOUNT
	status_effect.description = "-25% Damage"
	status_effect.rounds = -1
	status_effect.status_name = "Reallocation"
	status_effect.icon_color = Color.CHOCOLATE
	status_effect.quality = StatusEffect.EffectQuality.NEUTRAL
	# Allowing these to combine can cause problems when the owner cog dies
	status_effect.force_no_combine = true
	return status_effect

func end_boost() -> void:
	for effect in boost_effects:
		if effect.target in manager.battle_stats.keys():
			manager.expire_status_effect(effect)
			
func on_action_started(action: BattleAction) -> void:
	if action.user == target:
		if action is CogAttack and action.target_type != BattleAction.ActionTarget.SELF:
			action.damage *= 1 + calc_affected_amount() * 0.25 + player_attack
func calc_affected_amount() -> int:
	var count = 0
	for effect in boost_effects:
		if effect.target:
			count+= 1
	cogs_effected = count
	count -= 1 # bc of player
	return count

func get_description() -> String:
	var boost_amount = (calc_affected_amount() * 0.25 + player_attack) * 100
	description = "This foreman absorbed the attack of you and its collegues. Its own attack is boosted by %d%%!" % boost_amount
	return description		
