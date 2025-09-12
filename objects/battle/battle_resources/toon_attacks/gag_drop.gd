extends ToonAttack
class_name GagDrop

const DEBUFF := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres")

var skip_button_movie := false

func get_stats() -> String:
	var string := "Damage: " + get_true_damage() + "\n"\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			string += "Self"
		ActionTarget.ENEMIES:
			string += "All Cogs"
		ActionTarget.ENEMY:
			string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			string += "Three Cogs"

	string += "\nAftershock: %s" % get_true_damage(0.5)

	return string

func apply_debuff(target: Cog, damage_dealt: int) -> void:
	if sheer_force:
		return
	var new_effect: StatEffectAftershock = DEBUFF.duplicate()
	new_effect.amount = roundi(damage_dealt * 0.5)
	new_effect.description = "%d damage per round" % new_effect.amount
	new_effect.target = target
	if user.stats.get_stat("drop_aftershock_round_boost") != 0:
		new_effect.rounds += user.stats.get_stat("drop_aftershock_round_boost")
	manager.add_status_effect(new_effect)
