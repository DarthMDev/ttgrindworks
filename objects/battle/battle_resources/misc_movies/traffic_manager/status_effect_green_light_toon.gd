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
var gag_not_used = false

var traffic_toon: Player


func apply() -> void:
	traffic_toon = target
	trimmed_list = track_list.duplicate()
	manager.s_round_ended.connect(require_random_track)
	manager.s_round_started.connect(on_round_started)
	manager.s_ui_initialized.connect(require_random_track)
	manager.s_battle_ending.connect(expire_status)
	BattleService.s_battle_participant_died.connect(participant_died)

func cleanup() -> void:
	for ban_effect: StatusEffect in ban_effects:
		if ban_effect and is_instance_valid(ban_effect):
			manager.expire_status_effect(ban_effect)

	manager.s_round_ended.disconnect(require_random_track)
	manager.s_round_started.disconnect(on_round_started)
	BattleService.s_battle_participant_died.disconnect(participant_died)

func participant_died(who: Node3D) -> void:
	if who == traffic_toon:
		manager.expire_status_effect(self)

func expire_status() -> void:
	manager.expire_status_effect(self)
	

func require_random_track() -> void:
	for ban_effect in ban_effects:
		if ban_effect and is_instance_valid(ban_effect):
			#print("yarrgh")
			manager.expire_status_effect(ban_effect)
	if expires_this_round:
		return
	RandomService.array_shuffle_channel('true_random', trimmed_list)
	var new_track : Track = trimmed_list[0]
	var k = 1
	while all_cogs_lured() and (new_track.track_name == "Lure" or new_track.track_name == "Trap"):
		#print("in green light toon, when all ured")
		new_track = trimmed_list[k]
		k+= 1
		if k >= trimmed_list.size() - 1:
			break
	required_tracks[0] = new_track
	if Util.floor_number > 3 and new_track.track_name == "Sound":
		if RandomService.randi_channel('true_random') % 100 < 50:
			#print("IN GREEN LIGHT TOON: TRUE RANDOM STUFF")
			#print(RandomService.randi_channel('true_random') % 100)
			required_tracks[0] = trimmed_list[1]
			
	var new_effect := make_banned_effect(new_track.gags)
	manager.add_status_effect(new_effect)
	ban_effects[0] = new_effect
	#print(ban_effects)
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
	desc += "will result in -12% laff"
	return desc

func make_banned_effect(gags: Array[ToonAttack]) -> StatusEffect:
	round+= 1
	var banned_effect := GAG_BAN_EFFECT.duplicate()
	banned_effect.rounds = 0
	banned_effect.target = player
	banned_effect.banned_color = Color.DARK_GREEN      #Color.DARK_GREEN
	banned_effect.gags = gags
	return banned_effect
func renew() -> void:
	round+= 1
	await require_random_track()
	if gag_not_used:
		manager.battle_node.focus_character(target)
		manager.affect_target(target, Util.get_player().stats.max_hp * 0.12)
		if target is Player:
			target.set_animation('cringe')
			target.last_damage_source = "3n"
		else:
			target.last_damage_source = "Drop"
			target.set_animation('pie-small')
		await manager.sleep(3.0)
		await manager.check_pulses([target])
		gag_not_used = false
func on_round_started(actions: Array[BattleAction]) -> void:
	if rounds == 0:
		expires_this_round = true
	for effect in ban_effects:
		#print(effect)
		if typeof(effect) != TYPE_STRING:
			if not effect.is_banned_gag_used(actions):
				gag_not_used = true
				return
func all_cogs_lured() -> bool:
	var all_lured := true
	for cog in manager.cogs:
		if not cog.lured:
			all_lured = false
			break
	return all_lured

func all_cogs_trapped() -> bool:
	var all_trapped := true
	for cog in manager.cogs:
		if not cog.trap:
			all_trapped = false
			break
	return all_trapped
