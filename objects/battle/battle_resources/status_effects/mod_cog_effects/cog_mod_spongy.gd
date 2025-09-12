@tool
extends StatusEffect

const BOOST_AMOUNT := 1.515
const STAT_BOOST_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
var Recoil_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/recoil.tres")
var damage_redirected: float = 0.5 # 100 / 1.5 = 66 ||  66 / 0.5 == 0.33
var boost_effects: Array[StatBoost] = []

func apply() -> void:
	manager.s_participant_joined.connect(participant_joined)
	BattleService.s_toon_dealt_damage.connect(redirect_damage)
	
	var user: Cog = target
	for cog in manager.cogs:
		if not user == cog:
			apply_to_cog(cog)

func cleanup() -> void:
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	if BattleService.s_toon_dealt_damage.is_connected(redirect_damage):
		BattleService.s_toon_dealt_damage.disconnect(redirect_damage)
	end_boost()

func participant_joined(who: Node3D) -> void:
	if who is Cog:
		apply_to_cog(who)

func apply_to_cog(cog: Cog) -> void:
	var new_boost := create_boost(cog)
	manager.add_status_effect(new_boost)
	boost_effects.append(new_boost)

func create_boost(who: Cog) -> StatBoost:
	var status_effect := STAT_BOOST_RESOURCE.duplicate()
	status_effect.target = who
	status_effect.boost = BOOST_AMOUNT
	status_effect.stat = 'defense'
	status_effect.visible = false
	status_effect.rounds = -1
	status_effect.quality = StatusEffect.EffectQuality.POSITIVE
	# Allowing these to combine can cause problems when the owner cog dies
	status_effect.force_no_combine = true
	return status_effect

func end_boost() -> void:
	for effect in boost_effects:
		if effect.target in manager.battle_stats.keys():
			manager.expire_status_effect(effect)



func redirect_damage(_action: BattleAction, cog: Node3D, amount: int):
	if amount < 0 or cog == target:
		return
	if (not is_instance_valid(target)) or target.stats.hp <= 0:
		return
	var recoil: CogAttack = Recoil_Attack.duplicate()
	recoil.user = target
	recoil.targets = [target]
	recoil.damage = amount * damage_redirected
	recoil.action_name = "  "
	manager.inject_battle_action(recoil, 0)
