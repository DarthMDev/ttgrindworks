extends CCEffect

class_name CCPositiveAnomaly
const ANOMALIES_POSITIVE: Array[String] = [
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_overheal.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_record_profits.gd",
	"res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_organic_gags.gd",
]

func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	# add the anomaly to the floor
	# if we dont already have it 
	# make a new list out of the ones we dont have
	var anomalies = new_anomalies()
	if anomalies.size() > 0:
		var new_mod: String = RandomService.array_pick_random('floor_mods', anomalies)
		var loaded_mod: Script = Util.universal_load(new_mod)
		Util.floor_manager.add_anomaly(loaded_mod)
		return SUCCESS
	return FAILURE

func new_anomalies() -> Array[String]:
	var anomaly_files_pos: Array[String] = ANOMALIES_POSITIVE.duplicate()
	if Util.floor_manager.anomalies:
		for anomaly in Util.floor_manager.anomalies:
			if anomaly_files_pos.has(anomaly):
				anomaly_files_pos.erase(anomaly)
	return anomaly_files_pos

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if new_anomalies().size() > 0:
		return true
	return false
