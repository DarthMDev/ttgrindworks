@tool
extends StatusEffect
class_name StatusEffectGagImmunity

const ImmunityIcons: Dictionary = {
	"Trap": preload("res://ui_assets/battle/statuses/trap_immunity.png"),
	"Lure": preload("res://ui_assets/battle/statuses/lure_immunity.png"),
	"Sound": preload("res://ui_assets/battle/statuses/sound_immunity.png"),
	"Squirt": preload("res://ui_assets/battle/statuses/squirt_immunity.png"),
	"Throw": preload("res://ui_assets/battle/statuses/throw_immunity.png"),
	"Drop": preload("res://ui_assets/battle/statuses/drop_immunity.png"),
}

const FALLBACK_TRACK := preload('res://objects/battle/battle_resources/gag_loadouts/gag_tracks/throw.tres')

@export var track: Track

var cog: Cog

func apply() -> void:
	cog = target
	
	manager.s_action_started.connect(on_action_started)

func cleanup() -> void:
	if manager.s_action_started.is_connected(on_action_started):
		manager.s_action_started.disconnect(on_action_started)

## i dont think we need this anymore to be tbh honest with you guys
func on_action_started(action: BattleAction) -> void:
	if action is ToonAttack:
		if check_for_match(action):
			if cog in action.targets and action.targets.size() == 1:
				if not action is GagTrap:
					action.damage = 0

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

func randomize_effect() -> void:
	if is_instance_valid(Util.get_player()):
		var loadout := Util.get_player().stats.character.gag_loadout
		track = RandomService.array_pick_random('true_random', loadout.loadout)
	else:
		track = FALLBACK_TRACK
	rounds = RandomService.randi_range_channel('true_random', 1, 3)

func get_icon() -> Texture2D:
	return ImmunityIcons[track.track_name]

func get_status_name() -> String:
	return "%s Immunity" % track.track_name

func get_description() -> String:
	return "This Cog is immune to %s Gags" % track.track_name
