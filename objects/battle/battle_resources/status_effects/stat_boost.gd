@tool
extends StatusEffect
class_name StatBoost

var ICONS := {
	'damage': load("res://ui_assets/battle/statuses/damage.png"),
	'defense': load("res://ui_assets/battle/statuses/defense.png"),
	'evasiveness': load("res://ui_assets/battle/statuses/evasiveness.png"),
	'luck': load("res://ui_assets/battle/statuses/luck_crit.png"),
}

@export var stat: String = 'defense'
@export var boost: float = 1.0

var force_no_combine := false

func apply():
	var battle_stats: BattleStats = manager.battle_stats[target]
	if stat in battle_stats:
		battle_stats.set(stat,battle_stats.get(stat) * boost)

func expire():
	var battle_stats = manager.battle_stats[target]
	if stat in battle_stats:
		battle_stats.set(stat, battle_stats.get(stat) * 1.0 / boost) 

func get_description() -> String:
	return "%s%s%% %s" % ["+" if boost > 1.0 else "-", roundi(abs(boost - 1.0) * 100), stat[0].to_upper() + stat.substr(1)]

func get_icon() -> Texture2D:
	return ICONS[stat]

func get_status_name() -> String:
	return stat[0].to_upper() + stat.substr(1) + (" Up" if boost > 1.0 else " Down")

func combine(effect: StatusEffect) -> bool:
	if force_no_combine or effect.force_no_combine:
		return false

	if effect is StatBoost:
		if effect.stat == stat and effect.rounds == rounds and get_quality() == effect.get_quality():
			expire()
			boost *= effect.boost
			apply()
			print("new amount : %f" % boost)
			return true
	
	return false

func get_quality() -> EffectQuality:
	if boost >= 1.0:
		return EffectQuality.POSITIVE
	return EffectQuality.NEGATIVE
