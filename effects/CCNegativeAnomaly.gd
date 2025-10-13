# add a random negative anomaly to the floor
# if we dont already have it

extends CCEffect

class_name CCNegativeAnomaly



func _trigger(_instance: CCEffectInstance) -> EffectResult:
	randomize()
	# add the anomaly to the floor
	# if we dont already have it 
	# make a new list out of the ones we dont have
	var anomalies = new_anomalies()
	if anomalies.size() > 0:
		var new_mod: String = RNG.channel(RNG.ChannelFloorMods).pick_random(anomalies)
		var loaded_mod: Script = Util.universal_load(new_mod)
		Util.floor_manager.add_anomaly(loaded_mod)
		return SUCCESS
	return FAILURE

func new_anomalies() -> Array[String]:
	var anomalies = FloorVariant.ANOMALIES_NEGATIVE.duplicate()
	if Util.floor_manager.anomalies:
		for anomaly in Util.floor_manager.anomalies:
			if anomaly.get_mod_name() == "Out of Touch":
				anomalies.erase("res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_out_of_touch.gd")
	return anomalies

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if new_anomalies().size() > 0:
		return true
	return false
