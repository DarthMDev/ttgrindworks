@tool
extends StatusEffect

const GAG_BAN_EFFECT := preload('res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_order.tres')

var player: Player:
	get: return Util.get_player()
var track_list: Array[Track]:
	get: return player.stats.character.gag_loadout.loadout
var trimmed_list: Array[Track] = []
var required_tracks: Array = [""]
var ban_effects: Array = [""]
var expires_this_round := false
var round = 0

var traffic_man: Cog


func apply() -> void:
	traffic_man = target
	trimmed_list = track_list.duplicate()
	manager.s_round_ended.connect(require_random_track)
	manager.s_round_started.connect(on_round_started)
	manager.s_ui_initialized.connect(require_random_track)
	BattleService.s_battle_participant_died.connect(participant_died)

func cleanup() -> void:
	for ban_effect: StatusEffect in ban_effects:
		if ban_effect and is_instance_valid(ban_effect):
			manager.expire_status_effect(ban_effect)

	manager.s_round_ended.disconnect(require_random_track)
	manager.s_round_started.disconnect(on_round_started)
	BattleService.s_battle_participant_died.disconnect(participant_died)

func participant_died(who: Node3D) -> void:
	if who == traffic_man:
		manager.expire_status_effect(self)

func require_random_track() -> void:
	for ban_effect in ban_effects:
		if ban_effect and is_instance_valid(ban_effect):
			print("banned previous banns")
			manager.expire_status_effect(ban_effect)
	if expires_this_round:
		return
	RandomService.array_shuffle_channel('true_random', trimmed_list)
	var new_track : Track = trimmed_list[0]
	required_tracks[0] = new_track
	var new_effect := make_banned_effect(new_track.gags)
	manager.add_status_effect(new_effect)
	ban_effects[0] = new_effect
	manager.sleep(0.1)
	manager.battle_ui.refresh_turns()

func get_description() -> String:
	if round < 1:
		return "not yet ig"
	var desc := "Not using "
	for i in required_tracks.size():
		if i == required_tracks.size() - 1:
			if required_tracks.size() > 1: desc += " and "
			desc += required_tracks[i].track_name + " "
		elif i == 0:
			desc += required_tracks[i].track_name
		else: 
			desc += ", " + required_tracks[i].track_name
	desc += "will result in retaliation"
	desc+= '\nWanted to greenlight Altis on Steam 😭'
	return desc

func make_banned_effect(gags: Array[ToonAttack]) -> StatusEffect:
	round+= 1
	var banned_effect := GAG_BAN_EFFECT.duplicate()
	banned_effect.rounds = 0
	banned_effect.target = player
	banned_effect.banned_color = Color.DARK_GREEN
	banned_effect.gags = gags
	return banned_effect
func renew() -> void:
	round+= 1
	require_random_track()
func on_round_started(actions: Array[BattleAction]) -> void:
	if rounds == 0:
		expires_this_round = true
	print(ban_effects)
	for effect in ban_effects:
		if typeof(effect) != TYPE_STRING:
			if not effect.is_banned_gag_used(actions):
				var attack = load('res://objects/battle/battle_resources/cog_attacks/resources/finger_wag.tres').duplicate()
				attack.damage = 3
				attack.summary = "The Foreman Retaliates!"
				attack.user = traffic_man
				attack.targets = [Util.get_player()]
				attack.damage += traffic_man.level / 2 * 2 # yes i just did that
				manager.append_action(attack)
				return
