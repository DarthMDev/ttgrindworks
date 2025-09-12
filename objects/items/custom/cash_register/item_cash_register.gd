extends ItemScriptActive

const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
const SFX := preload("res://audio/sfx/items/cash_register.ogg")

func use() -> void:
	var player := Util.get_player()
	if player.stats.money < 15:
		cancel_use()
		return
	
	AudioManager.play_sound(SFX)
	player.bean_jar.scale_shrink()
	player.stats.money -= 15
	var stat_boost := STAT_BOOST_REFERENCE.duplicate()
	stat_boost.quality = StatusEffect.EffectQuality.POSITIVE
	stat_boost.stat = 'damage'
	stat_boost.boost = 1.15
	stat_boost.rounds = 1
	stat_boost.target = player
	BattleService.ongoing_battle.add_status_effect(stat_boost)
	BattleService.s_refresh_statuses.emit()
