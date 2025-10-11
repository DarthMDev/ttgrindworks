extends ItemScriptActive


func use() -> void:
	var stats := Util.get_player().stats
	stats.hp = randi_range(1, stats.max_hp)
