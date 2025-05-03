extends ItemScript

func on_collect(item : Item, _model : Node3D) -> void:
	var player := Util.get_player()
	var game_floor := Util.floor_manager
	
	# Make sure our instances are valid
	if not is_instance_valid(game_floor) or not is_instance_valid(player):
		return
	
	# If we were the floor reward, we shouldn't add a new anomaly
	if game_floor.floor_variant.reward == item:
		return
	
	try_add_anomaly(player, game_floor)

func try_add_anomaly(player : Player, game_floor : GameFloor) -> void:
	game_floor.spawn_new_anomalies(1)
