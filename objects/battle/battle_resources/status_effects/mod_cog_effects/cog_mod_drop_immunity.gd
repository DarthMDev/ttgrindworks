
@tool
extends StatusEffect
class_name StatusEffectGagImmunity1 #I added a 1 just incase the names of this class matter in any way

const immune_icon = preload("res://ui_assets/battle/statuses/drop_immunity.png")
const gag_status = preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres")


@export var track: Track = preload("res://objects/battle/battle_resources/gag_loadouts/gag_tracks/drop.tres")

var cog: Cog

func apply() -> void:
	cog = target
	#description = "Immune to %s gags" % track.track_name
	#manager.s_action_started.connect(on_action_started)
	visible = false
	var gag_immunity = gag_status.duplicate()
	gag_immunity.rounds = -1
	gag_immunity.target = cog
	gag_immunity.set_track(track)
	gag_immunity.status_name = "Prethinking"
	gag_immunity.oftf_cheat = true # for returning prethingk status name instead of default
	manager.add_status_effect(gag_immunity)

func cleanup() -> void:
	pass
	#if manager.s_action_started.is_connected(on_action_started):
		#manager.s_action_started.disconnect(on_action_started)

func on_action_started(action: BattleAction) -> void:
	if action is ToonAttack:
		if check_for_match(action):
			if cog in action.targets and action.targets.size() == 1:
				action.damage = -1

func check_for_match(action: ToonAttack) -> bool:
	for gag in track.gags:
		if gag.action_name == action.action_name:
			return true
	return false

func set_track(new_track: Track) -> void:
	track = new_track
	if cog and cog.virtual_cog:
		cog.body.set_color(Color(track.track_color, 0.8))
	description = "Immune to %s gags" % track.track_name

func get_icon() -> Texture2D:
	return immune_icon

func get_status_name() -> String:
	return "%s Immunity" % track.track_name
