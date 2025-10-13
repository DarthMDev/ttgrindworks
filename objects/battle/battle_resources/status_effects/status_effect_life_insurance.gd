@tool
extends StatusEffect



func apply():
	target.stats.hp_changed.connect(on_target_hp_changed)

func on_target_hp_changed(hp: int) -> void:
	if hp == 0 and target.stats.extra_lives == 0:
		target.stats.hp = 1

func combine(effect: StatusEffect) -> bool:
	rounds += effect.rounds + 100
	return true
