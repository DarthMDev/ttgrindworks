@tool
extends StatusEffect

const BOOST_AMOUNT := 1.25
const STAT_BOOST_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")

var boost_effects: Array[StatBoost] = []

func apply() -> void:
	manager.s_participant_joined.connect(participant_joined)
	
	var user: Cog = target
	for cog in manager.cogs:
		if not user == cog:
			apply_to_cog(cog)

func cleanup() -> void:
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	end_boost()

func participant_joined(who: Node3D) -> void:
	if who is Cog:
		apply_to_cog(who)

func apply_to_cog(cog: Cog) -> void:
	var new_boost := create_boost(cog)
	manager.add_status_effect(new_boost)
	boost_effects.append(new_boost)

func create_boost(who: Cog) -> StatBoost:
	var status_effect := STAT_BOOST_RESOURCE.duplicate()
	status_effect.target = who
	status_effect.boost = BOOST_AMOUNT
	status_effect.stat = 'defense'
	status_effect.description = "+25% Defense"
	status_effect.rounds = -1
	status_effect.quality = StatusEffect.EffectQuality.POSITIVE
	# Allowing these to combine can cause problems when the owner cog dies
	status_effect.force_no_combine = true
	return status_effect

func end_boost() -> void:
	for effect in boost_effects:
		if effect.target in manager.battle_stats.keys():
			manager.expire_status_effect(effect)
