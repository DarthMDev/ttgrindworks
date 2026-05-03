extends ItemScriptActive

const STAT_BOOST_REFERENCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
const SFX := preload("res://audio/sfx/items/cash_register.ogg")
const ROUNDS := 0
const BOOST_AMT := 0.1
const COST := 3

func validate_use() -> bool:
	return Util.get_player().stats.money >= COST

func use() -> void:
	var player := Util.get_player()
	
	AudioManager.play_sound(SFX)
	player.bean_jar.scale_shrink()
	player.stats.money -= COST
	var stat_boost := STAT_BOOST_REFERENCE.duplicate(true)
	stat_boost.quality = StatusEffect.EffectQuality.POSITIVE
	stat_boost.stat = 'damage'
	stat_boost.boost = BOOST_AMT
	stat_boost.rounds = ROUNDS
	stat_boost.target = player
	BattleService.ongoing_battle.add_status_effect(stat_boost)
	BattleService.s_refresh_statuses.emit()
	if player.gags_cost_beans:
		BattleService.ongoing_battle.battle_ui.refresh_tracks()
