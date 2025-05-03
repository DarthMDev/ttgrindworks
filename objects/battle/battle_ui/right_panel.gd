extends Control

# Child References
@onready var gag_info := $GagInfo
@onready var gag_name := $GagInfo/GagName
@onready var gag_stats := $GagInfo/GagStats
@onready var gag_icon := $GagInfo/GagIcon
@onready var player_stats : Label = %PlayerStats
@onready var regen_stats : Label = %RegenSlips
@onready var player_info : Control = %CurrentStats

var stats : PlayerStats:
	get: return BattleService.ongoing_battle.battle_stats[Util.get_player()]

func _ready() -> void:
	update_stats_text()

func preview_gag(gag: BattleAction):
	if not gag:
		clear_display()
		return
	player_info.hide()
	
	gag_info.show()
	gag_name.text = gag.action_name
	gag_stats.text = gag.get_stats()
	gag_icon.texture = gag.icon

func clear_display() -> void:
	gag_info.hide()
	update_stats_text()
	player_info.show()

func update_stats_text() -> void:
	var display_stats : Array[String] = ['damage', 'defense', 'evasiveness', 'luck']
	#$CurrentStats/RegenSlips.set_text("Gag Regeneration: %d" % stats.gag_regeneration['Throw'])
	$CurrentStats/PlayerStats.set_text("")
	for stat in display_stats:
		var stat_title : String = stat
		stat_title[0] = stat_title[0].to_upper()
		$CurrentStats/PlayerStats.text += "%s: %d%%\n" % [stat_title, stats.get_stat_as_percent(stat)]
