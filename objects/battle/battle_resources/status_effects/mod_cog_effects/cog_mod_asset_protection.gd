@tool
extends StatusEffect

const BOOST_AMOUNT := 0.25
const IMMUNITY_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres")

var boost_effects: Array[StatusEffect] = []
var track: Track
var player: Player:
	get: return Util.get_player()

func apply() -> void:
	manager.s_participant_joined.connect(participant_joined)
	
	roll_for_track()
	
	var user: Cog = target
	for cog in manager.cogs:
		if not user == cog:
			apply_to_cog(cog)

func roll_for_track() -> void:
	track = player.stats.character.gag_loadout.loadout.pick_random()

func cleanup() -> void:
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	end_boost()

func participant_joined(who: Node3D) -> void:
	if who is Cog:
		apply_to_cog(who)

func get_description() -> String:
	return "All other Cogs are immune to %s while this Cog is in battle" % track.track_name

func apply_to_cog(cog: Cog) -> void:
	var new_boost := create_boost(cog)
	manager.add_status_effect(new_boost)
	boost_effects.append(new_boost)

func create_boost(who: Cog) -> StatusEffectGagImmunity:
	var status_effect: StatusEffectGagImmunity = IMMUNITY_RESOURCE.duplicate(true)
	status_effect.target = who
	status_effect.track = track
	status_effect.rounds = -1
	status_effect.quality = StatusEffect.EffectQuality.POSITIVE
	return status_effect

func end_boost() -> void:
	for effect in boost_effects:
		if effect.target in manager.battle_stats.keys():
			manager.expire_status_effect(effect)
