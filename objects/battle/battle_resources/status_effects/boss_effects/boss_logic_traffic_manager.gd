@tool
extends StatusEffect
class_name TrafficManagerLogic

const ACTION_GREEN_LIGHT := preload("res://objects/battle/battle_resources/misc_movies/traffic_manager/green_light.tres")
const ACTION_RED_LIGHT := preload("res://objects/battle/battle_resources/misc_movies/traffic_manager/red_light.tres")
const ACTION_RETALIATION := preload('res://objects/battle/battle_resources/misc_movies/traffic_manager/traffic_jam.tres')

var traffic_man: Cog:
	get: return target
var gag_tracks: Array[Track]:
	get: return Util.get_player().stats.character.gag_loadout.loadout

var green_light := true

# Called by battle manager on initial application
func apply() -> void:
	rounds = -1
	manager.s_round_started.connect(round_started)

func swap_mode() -> void:
	green_light = not green_light
	if green_light:
		queue_green_light()
	else:
		queue_red_light()

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func round_started(_actions: Array[BattleAction]) -> void:
	if manager.current_round % 3 == 1:
		swap_mode()

func queue_green_light() -> void:
	var action := ACTION_GREEN_LIGHT.duplicate(true)
	action.user = target
	action.logic_effect = self
	action.targets = [Util.get_player()]
	manager.round_end_actions.append(action)

func queue_red_light() -> void:
	var action := ACTION_RED_LIGHT.duplicate(true)
	action.user = target
	action.logic_effect = self
	action.targets = [Util.get_player()]
	manager.round_end_actions.append(action)

func on_banned_gag_used(_action : ToonAttack) -> void:
	queue_retaliation()

func queue_retaliation() -> void:
	var action := ACTION_RETALIATION.duplicate(true)
	action.user = target
	action.targets = [Util.get_player()]
	manager.round_end_actions.append(action)
