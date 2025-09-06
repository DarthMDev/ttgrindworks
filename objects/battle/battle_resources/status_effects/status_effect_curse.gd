@tool
extends StatusEffect

const EffectIcons: Dictionary = {
	"Trap": preload("res://ui_assets/battle/statuses/budget_trap.png"),
	"Lure": preload("res://ui_assets/battle/statuses/budget_lure.png"),
	"Sound": preload("res://ui_assets/battle/statuses/budget_sound.png"),
	"Squirt": preload("res://ui_assets/battle/statuses/budget_squirt.png"),
	"Throw": preload("res://ui_assets/battle/statuses/budget_throw.png"),
	"Drop": preload("res://ui_assets/battle/statuses/budget_drop.png"),
}

@export var track_name: String

var player: Player:
	get: return target
var saved_regen := 0
var force_no_combine = false

func apply() -> void:
	manager.s_battle_ending.connect(expire_status)
	description = "%s points reduced and point regeneration disabled" % track_name
	if player.stats.gag_regeneration.has(track_name):
		saved_regen = player.stats.gag_regeneration[track_name]
		player.stats.gag_regeneration[track_name] = 0
		player.stats.gag_balance[track_name] -= 12

func expire() -> void:
	if player.stats.gag_regeneration.has(track_name):
		player.stats.gag_regeneration[track_name] = saved_regen

func expire_status() -> void:
	manager.expire_status_effect(self)
func get_icon() -> Texture2D:
	return EffectIcons[track_name]

func combine(effect: StatusEffect) -> bool:
	if not effect.status_name == "Curse":
		return false
	
	if force_no_combine or effect.force_no_combine:
		return false

	if effect.track_name == track_name:
			#expire()
			player.stats.gag_balance[track_name] -= 12
			effect.rounds += 1
			print("same name regen")
			#apply()
			#print("new amount : %f" % boost)
			return true
	
	return false
