extends ItemScript


func on_collect(_item : Item, _node : Node3D) -> void:
	var game_floor : GameFloor = Util.floor_manager
	if not is_instance_valid(game_floor):
		return
	
	for anomaly in game_floor.anomalies.duplicate():
		if anomaly.get_mod_quality() == FloorModifier.ModType.NEGATIVE:
			#game_floor.remove_anomaly(anomaly)
			Util.get_player().boost_queue.queue_text("Nothing happened 💀", anomaly.text_color)
