@tool
extends StatusEffect

const GAG_BAN_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_order.tres')

var banned_effect: StatusEffect
var logic_effect: StatusEffect
var player: Player:
	get: return target
var track_list: Array[Track]:
	get: return player.stats.character.gag_loadout.loadout
var trimmed_list: Array[Track] = []
var banned_tracks: Array[Track] = []
var retaliation_queued := false

var traffic_man: Cog


func apply() -> void:
	traffic_man = logic_effect.traffic_man
	trimmed_list = track_list.duplicate()
	for i in range(trimmed_list.size() - 1, -1, -1):
		#remove throw from list for banning
		if trimmed_list[i].track_name == "Throw":
			trimmed_list.remove_at(i)
	#new_track.track_name == "Throw"
	# Create the gag ban effect
	banned_effect = GAG_BAN_EFFECT.duplicate()
	banned_effect.rounds = rounds
	banned_effect.target = player
	banned_effect.s_banned_gag_used.connect(on_banned_gag_used)
	ban_random_track()
	manager.add_status_effect(banned_effect)
	manager.s_round_started.connect(ban_random_track)
	manager.s_round_ended.connect(on_round_ended)
	BattleService.s_battle_participant_died.connect(participant_died)

func cleanup() -> void:
	if banned_effect and is_instance_valid(banned_effect):
		manager.expire_status_effect(banned_effect)
		banned_effect = null
	manager.s_round_ended.disconnect(on_round_ended)
	manager.s_round_started.disconnect(ban_random_track)
	BattleService.s_battle_participant_died.disconnect(participant_died)

func participant_died(who: Node3D) -> void:
	if who == traffic_man:
		manager.expire_status_effect(self)

func on_round_ended() -> void:
	retaliation_queued = false

func ban_random_track(_actions: Array[BattleAction] = []) -> void:
	RandomService.array_shuffle_channel('true_random', trimmed_list)
	var new_track: Track = trimmed_list.pop_back()
	for gag in new_track.gags:
		banned_effect.gags.append(gag)
	banned_tracks.append(new_track)

func get_description() -> String:
	var desc := "Using "
	for i in banned_tracks.size():
		if i == banned_tracks.size() - 1:
			if banned_tracks.size() > 1: desc += " or "
			desc += banned_tracks[i].track_name + " "
		elif i == 0:
			desc += banned_tracks[i].track_name
		else: 
			desc += ", " + banned_tracks[i].track_name
	desc += "will result in harsh retaliation"
	return desc

func on_banned_gag_used(_action: ToonAttack) -> void:
	if not retaliation_queued:
		retaliation_queued = true
		logic_effect.queue_retaliation()
