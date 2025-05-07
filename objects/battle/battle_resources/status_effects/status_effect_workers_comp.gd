@tool
extends StatBoost

## This kinda turned into the ship of theseus
## Does it truly extend stat boost?
## Kinda

const AFFECTED_STATS : Array[String] = ['damage', 'defense']

func apply():
	var battle_stats: BattleStats = manager.battle_stats[target]
	for stat_ in AFFECTED_STATS:
		if stat_ in battle_stats:
			battle_stats.set(stat_,battle_stats.get(stat_) * boost)

func expire():
	var battle_stats = manager.battle_stats[target]
	for stat_ in AFFECTED_STATS:
		if stat_ in battle_stats:
			battle_stats.set(stat_, battle_stats.get(stat_) * 1.0 / boost)

func get_description() -> String:
	var return_string := ""
	for stat_ in AFFECTED_STATS:
		return_string += "%s%s%% %s" % ["+" if boost > 1.0 else "-", roundi(abs(boost - 1.0) * 100), stat_[0].to_upper() + stat_.substr(1)]
		if not AFFECTED_STATS.find(stat_) == AFFECTED_STATS.size() -1:
			return_string += "\n"
	return return_string

func get_icon() -> Texture2D:
	return icon

func get_status_name() -> String:
	return status_name

func combine(effect: StatusEffect) -> bool:
	if force_no_combine or effect.force_no_combine:
		return false
	
	if effect is StatBoost:
			expire()
			boost = get_combined_boost(boost, effect.boost)
			rounds = 1
			apply()
			return true
	
	return false
