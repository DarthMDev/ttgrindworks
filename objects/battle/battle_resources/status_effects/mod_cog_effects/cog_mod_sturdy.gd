@tool
extends StatusEffect


func apply() -> void:
	target.stats.hp_changed.connect(on_hp_changed)

func on_hp_changed(hp: int) -> void:
	if hp == 0:
		target.stats.hp = 1
		target.stats.hp_changed.disconnect(on_hp_changed)
