extends ToonAttack
class_name GagTrap

# Signals when trap movie is over
signal s_trap
signal s_activate

var baked_crit_chance := 0.0
var activating_lure: GagLure = null

# Runs when a Cog is lured into the trap
func activate():
	pass

## Get a properly ID'd version of the trap effect specified
func get_trap_effect() -> StatusTrapped:
	var new_effect := StatusTrapped.new()
	new_effect.quality = StatusEffect.EffectQuality.NEGATIVE
	new_effect.gag = self
	new_effect.rounds = -1
	s_activate.connect(manager.expire_status_effect.bind(new_effect))
	
	return new_effect

func apply_trap_effect(who: Cog) -> void:
	var effect := get_trap_effect()
	effect.target = who
	manager.add_status_effect(effect)

func apply_extra_knockback(cog: Cog) -> void:
	if not activating_lure:
		return
	if (not Util.get_player()) or is_equal_approx(Util.get_player().stats.trap_knockback_percent, 0.0):
		return

	var boost_percent: float = Util.get_player().stats.trap_knockback_percent
	manager.do_standalone_knockback_damage(cog, roundi(activating_lure.get_lure_effect().knockback_effect * boost_percent))
