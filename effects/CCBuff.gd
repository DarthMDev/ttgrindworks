extends CCEffect

class_name CCBuff

var player = Util.get_player()
# applies a buff to the player
# only while the player is in battle
# same as high dive but a random buff instead of all

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var toonup = ToonUp.new()
	var effects = toonup.get_ladder_effects()
	var effect = effects[randi() % effects.size()]
	effect.target = player
	BattleService.ongoing_battle.add_status_effect(effect)
	AudioManager.play_sound(player.toon.yelp)
	BattleService.s_refresh_statuses.emit()
	return SUCCESS

func _can_run() -> bool:
	if player != null and player.stats.hp > 0:
		return true
	if BattleService.ongoing_battle != null:
		return true
	return false
