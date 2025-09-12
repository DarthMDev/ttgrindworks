extends ToonAttack
class_name GagLure

const LURED_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_lured.tres")

@export var lure_effect: StatusLured
var trap_gags: Array[GagTrap] = []
# Required for crit storage to work properly
var current_activating_trap: GagTrap = null


func get_stats() -> String:
	if not lure_effect:
		return "NO LURE EFFECT SET UP"

	var player_stats: PlayerStats
	if is_instance_valid(BattleService.ongoing_battle):
		player_stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
	else:
		player_stats = Util.get_player().stats

	var knockback_damage: int = lure_effect.get_true_knockback()
	var string := "Knockback Damage: " + str(knockback_damage) + "\n"\
	+ "Rounds: " + str(lure_effect.rounds) +"\n"\
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
	string += "\nApplies: " + lure_effect.get_effect_string()
	return string


## Get a properly ID'd version of the lure effect specified
func get_lure_effect() -> StatusLured:
	var new_effect := LURED_EFFECT.duplicate()
	
	# Copy the attributes from the reference value
	if lure_effect:
		new_effect.quality = StatusEffect.EffectQuality.NEGATIVE
		new_effect.icon = icon
		new_effect.lure_type = lure_effect.lure_type
		if sheer_force: new_effect.lure_type = lure_effect.LureType.DAMAGE_DOWN
		new_effect.knockback_effect = lure_effect.knockback_effect
		new_effect.damage_nerf = lure_effect.damage_nerf
	
	return new_effect

func apply_lure(who: Cog) -> void:
	var effect := get_lure_effect()
	effect.target = who
	if not who == main_target:
		effect.damage_nerf += effect.damage_nerf / 2.0
	if sheer_force: effect.damage_nerf = 1
	manager.add_status_effect(effect)
