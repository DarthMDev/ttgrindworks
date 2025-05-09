# adds a random neutral anomaly to the floor
# if we dont already have it

extends CCEffect

class_name CCNeutralAnomaly



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
		if loaded_mod.get_mod_name() == "Marathon":
			# if we are in the shop we should refund the user as the next room is a boss room
			if Util.floor_manager.get_current_room() in Util.floor_manager.floor_rooms.pre_final_rooms or Util.floor_manager.get_current_room() in Util.floor_manager.floor_rooms.final_rooms:
				# we are in the shop or we are in the boss room
				# we need to refund the user
				return FAILURE
			# we need to emit the signal for marathon so any listeners can pick it up
			# and add an extra room
			Util.floor_manager.s_marathon_triggered.emit()
			
		return SUCCESS
	return FAILURE

func new_anomalies() -> Array[String]:
	var anomalies = FloorVariant.ANOMALIES_NEUTRAL.duplicate()
	# TODO , rework marathon to queue marathon to next floor
	anomalies.erase("res://scenes/game_floor/floor_modifiers/scripts/anomalies/floor_mod_marathon.gd")
	return anomalies

func _can_run() -> bool:
	var player = Util.get_player()
	if player != null and player.stats.hp > 0:
		return true
	if new_anomalies().size() > 0:
		return true
	return false
