extends Node


var score: Dictionary[StringName, int] = {}
var cogs_defeated_this_round := 0
var hit_this_floor := false

#region Score Channels
const ChannelCogsDefeated := &'Cog Crusher'
const ChannelTimeBonus := &'Punctual Performer'
const ChannelMinMax := &'Secret Sleuther' 
const ChannelBosses := &'Boss Basher'
const ChannelDodge := &'Evasion Expert'
const ChannelItemBonus := &'Curious Collector'
const ChannelAnomalyBonus := &'Chaos Catalyst'
const ChannelStrangerTrade := &'Dubious Dealer'
const ChannelMoney := &'Money Maker'
const ChannelQuests := &'Task Taker'

# Controls the order that channels are displayed on the win screen
var channel_hierarchy: Array[StringName] = [
	ChannelTimeBonus,
	ChannelDodge,
	ChannelCogsDefeated,
	ChannelBosses,
	ChannelMoney,
	ChannelQuests,
	ChannelAnomalyBonus,
	ChannelItemBonus,
	ChannelStrangerTrade,
	ChannelMinMax,
]

# Optional Negative Labels for score categories
var negative_channels: Dictionary[StringName, StringName] = {
	ChannelDodge: &'Clumsy Creature',
	ChannelTimeBonus: &'Lazy Laggard',
}

# Append score channels that should not be counted mid-gameplay
var final_tally_only_channels: Array[StringName] = [
	ChannelTimeBonus,
	ChannelDodge,
]
#endregion

#region Point Standards
const TIME_BONUS := 6000 # Ticks down over the run
const COG_BONUS := 3 # Base bonus points for defeating a Cog
const COMBO_BONUS := 5 # Bonus points for defeating more than 1 Cog in the same round
const LEVEL_BONUS := 2 # Bonus points per level of Cog defeated
const PROXY_BONUS := 8 # Bonus points for defeating a Proxy Cog
const BOSS_BONUS := 150 # Bonus Points for defeating a boss
const EVASION_BONUS := 3000 # Loses points every time the player is hit in real time
const NO_HIT_FLOOR := 250 # Points awarded for completing a floor without taking realtime damage (scales per floor)
const HURT_PENALTY := -200 # Evasion penalty on taking damage in real time
const STRANGER_BONUS := 250 # Bonus per Item gained from Stranger
const ITEM_STAR_BONUS := 50 # Bonus per star for each Item taken
const BEAN_BONUS := 5 # Bonus points per Jellybean collected
const ANOMALY_BONUS := 120 # Bonus points per anomaly taken
const ANOMALY_STACK_BONUS := 1.2 # Stacking bonus for anomaly combining
const QUEST_BONUS := 175 # Bonus points per quest completed
#endregion

func _ready() -> void:
	SaveFileService.s_reset.connect(on_run_reset)
	Util.s_floor_started.connect(on_floor_start)
	Util.s_floor_ended.connect(on_floor_end)
	prepare_score_tracking()

func on_run_reset() -> void:
	score.clear()
	# Default Bonuses
	set_channel_score(ChannelTimeBonus, TIME_BONUS)
	set_channel_score(ChannelDodge, EVASION_BONUS)

func load_score_from_file(file: SaveFile) -> void:
	score.clear()
	for channel in file.score:
		score[channel] = file.score[channel]

func set_channel_score(channel: StringName, points: int) -> void:
	score[channel] = points

func get_channel_score(channel: StringName) -> int:
	if not channel in score:
		return 0
	return score[channel]

func modify_score(channel: StringName, points: int) -> void:
	if not channel in score:
		set_channel_score(channel, points)
		return
	score[channel] += points

func get_active_categories() -> Array[StringName]:
	var active_categories := score.keys()
	var channels: Array[StringName] = []
	for channel in channel_hierarchy:
		if channel in active_categories:
			channels.append(channel)
	for channel in score:
		if not channel in channels:
			channels.append(channel)
	return channels

#region Score Tracking
func prepare_score_tracking() -> void:
	
	# Battle Trackers
	BattleService.s_cog_died.connect(on_cog_died)
	BattleService.s_round_ended.connect(on_battle_round_ended)
	
	# Player trackers
	Util.s_player_assigned.connect(on_player_assigned)
	
	# Item Trackers
	ItemService.s_item_applied.connect(on_item_taken)
	Globals.s_stranger_bought_item.connect(on_stranger_trade)
	
	# Misc
	Globals.s_quest_completed.connect(on_quest_complete)

func on_player_assigned(player: Player) -> void:
	player.s_stats_connected.connect(on_stats_connected)
	player.s_hurt_realtime.connect(on_player_hurt)

func on_stats_connected(stats: PlayerStats) -> void:
	stats.s_money_changed.connect(on_money_changed)

func on_player_hurt(_dmg) -> void:
	modify_score(ChannelDodge, HURT_PENALTY)
	hit_this_floor = true

func on_item_taken(item: Item) -> void:
	if not is_instance_valid(Util.get_player()): return
	
	# Disregard character starting items
	var item_name := item.item_name
	var character := Util.get_player().character
	for itm: Item in character.starting_items:
		if itm.item_name == item.item_name:
			return
	
	var star_count := (item.qualitoon as int) + 1
	modify_score(ChannelItemBonus, ITEM_STAR_BONUS * star_count)

func on_stranger_trade() -> void:
	modify_score(ChannelStrangerTrade, STRANGER_BONUS)

func on_money_changed(current_money: int) -> void:
	set_channel_score(ChannelMoney, current_money * BEAN_BONUS)

func on_battle_round_ended(_manager) -> void:
	cogs_defeated_this_round = 0

func on_cog_died(cog: Cog) -> void:
	if not BattleService.cog_gives_credit(cog): return
	
	if is_instance_valid(BattleService.ongoing_battle):
		cogs_defeated_this_round += 1
	
	# Calculate the point bonus this Cog should grant
	var bonus := COG_BONUS
	bonus += LEVEL_BONUS * cog.level
	bonus += COMBO_BONUS * (cogs_defeated_this_round - 1)
	if cog.dna.is_mod_cog:
		bonus += PROXY_BONUS
	modify_score(ChannelCogsDefeated, bonus)
	
	print("cog bonus granted: %d" % bonus)
	
	# Also check for Boss Cogs
	if cog.dna.cog_name in BattleService.BOSS_COG_NAMES:
		on_boss_defeated()

func on_boss_defeated() -> void:
	modify_score(ChannelBosses, BOSS_BONUS)

func get_point_total(final_tally := true) -> int:
	var total := 0
	for channel in score:
		if final_tally or not channel in final_tally_only_channels:
			total += score[channel]
	return total

func on_floor_start(gfloor: GameFloor) -> void:
	var anomaly_bonus := ANOMALY_BONUS
	for i in gfloor.floor_variant.anomalies.size():
		modify_score(ChannelAnomalyBonus, anomaly_bonus)
		anomaly_bonus = ceili(anomaly_bonus * ANOMALY_STACK_BONUS)
	hit_this_floor = false

func on_floor_end() -> void:
	if not hit_this_floor:
		modify_score(ChannelDodge, NO_HIT_FLOOR * maxi(Util.floor_number + 1, 1))

func on_quest_complete() -> void:
	modify_score(ChannelQuests, QUEST_BONUS)

#endregion
