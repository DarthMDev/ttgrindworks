extends CCEffect

class_name CCDOTEffect

const CROWD_CONTROL_BURN = preload("res://objects/battle/battle_resources/status_effects/resources/crowd_control_burn.tres")
 
# applies a damage over time effect only if the player is in battle

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	BattleService.ongoing_battle.add_status_effect(CROWD_CONTROL_BURN)
	AudioManager.play_sound(player.toon.yelp)
	BattleService.s_refresh_statuses.emit()
	return SUCCESS

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if BattleService.ongoing_battle:
		return true
	return false
