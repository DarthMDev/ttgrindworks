extends CCEffect

class_name CCNerf
# taken from financial report
const STAT_BOOST := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")

const BoostNums := {
	'damage': 0.7,
	'defense': 0.8,
	'luck': 0.7,
	'evasiveness': 0.7,
}

# applies a nerf to the player
# only while the player is in battle
# similar to book keeper
func _trigger(_instance: CCEffectInstance) -> EffectResult:
	var player = Util.get_player()
	var new_debuff := STAT_BOOST.duplicate()
	new_debuff.target = player
	new_debuff.rounds = 2
	new_debuff.quality = StatusEffect.EffectQuality.NEGATIVE
	var rng = RNG.channel(RNG.ChannelTrueRandom)
	var stat_keys = BoostNums.keys()
	new_debuff.stat = stat_keys[rng.randi_range(0, stat_keys.size() - 1)]
	new_debuff.boost = BoostNums[new_debuff.stat]
	BattleService.ongoing_battle.add_status_effect(new_debuff)
	AudioManager.play_sound(player.toon.yelp)
	BattleService.s_refresh_statuses.emit()
	return SUCCESS
	
func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if BattleService.ongoing_battle != null:
		return true
	return false
