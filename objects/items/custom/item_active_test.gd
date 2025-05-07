extends ItemScriptActive


func use() -> void:
	var stats := Util.get_player().stats
	stats.hp = RandomService.randi_range_channel('true_random', 1, stats.max_hp)
