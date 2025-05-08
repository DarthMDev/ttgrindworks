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
	if not effect is StatBoost:
		return false
	
	if force_no_combine or effect.force_no_combine:
		return false

	if effect is StatBoost:
		if effect.stat == stat and effect.rounds == rounds and get_quality() == effect.get_quality():
			expire()
			boost = get_combined_boost(boost, effect.boost)
			apply()
			print("new amount : %f" % boost)
			return true
	
	return false

func get_quality() -> EffectQuality:
	if boost >= 1.0:
		return EffectQuality.POSITIVE
	return EffectQuality.NEGATIVE

func randomize_effect() -> void:
	stat = RandomService.array_pick_random('true_random', ICONS.keys())
	rounds = RandomService.randi_range_channel('true_random', 1, 3)
	boost = RandomService.randf_range_channel('true_random', 0.75, 1.25)
	if boost > 1.0:
		quality = StatusEffect.EffectQuality.POSITIVE
	else:
		quality = StatusEffect.EffectQuality.NEGATIVE

func get_combined_boost(boost1: float, boost2: float) -> float:
	return boost1 + (boost2 - 1.0)
