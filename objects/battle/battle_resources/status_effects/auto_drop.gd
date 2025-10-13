@tool
extends StatusEffect
class_name StatusAutoDrop

@export var drop_gag: GagDrop

func apply() -> void:
	manager.s_round_started.connect(round_started)

func cleanup() -> void:
	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func round_started(actions: Array[BattleAction]) -> void:
	var new_drop: GagDrop = drop_gag.duplicate(true)
	new_drop.targets = [target]
	new_drop.user = Util.get_player()
	new_drop.special_action_exclude = true
	new_drop.skip_button_movie = true
	new_drop.track = load('res://objects/battle/battle_resources/gag_loadouts/gag_tracks/drop.tres')
	var drop_index := find_inject_pos(actions)

	manager.inject_battle_action(new_drop, drop_index)

func find_inject_pos(actions: Array[BattleAction]) -> int:
	var drop_index := 0
	var found_player := false
	while drop_index < actions.size():
		var action: BattleAction = actions[drop_index]
		if action is ToonAttack:
			found_player = true
		if action is CogAttack and found_player:
			break
		drop_index += 1
	if found_player == false:
		drop_index = 0
		while drop_index < actions.size() and BattleAction.ActionTag.PRIORITY_ACTION in actions[drop_index].action_tags:
			drop_index += 1
	return drop_index

func get_icon() -> Texture2D:
	return drop_gag.icon

func get_status_name() -> String:
	return "Incoming Drop"

func get_description() -> String:
	return "Will be hit by %s\nDamage: %s" % [drop_gag.action_name, drop_gag.get_true_damage(1.0, 0, load('res://objects/battle/battle_resources/gag_loadouts/gag_tracks/drop.tres'))]
