@tool
extends StatusEffect
class_name ScapegoatLogic

var Recoil_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/recoil.tres")
var damage_redirected: float = 0.5 # 100 / 1.5 = 66 ||  66 / 0.5 == 0.33
var boost_effects: Array[StatBoost] = []
const STAT_BOOST_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres")
const ATTENTIVE_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/resources/attentive.tres")
const LURE_IMUN_RESOURCE := preload("res://objects/battle/battle_resources/status_effects/mod_cog_effects/mod_cog_lure_immunity.tres")
var Shield_Up_Attack = preload("res://objects/battle/battle_resources/cog_attacks/resources/shields_up.tres")
var PLACEHOLDER_ATTACK = preload("res://objects/battle/battle_resources/cog_attacks/resources/placeholder.tres")

var sheilds_up = true
var enraged = false
var desperation = false
var rage = 0
var rage_turns = 1

# Called by battle manager on initial application
func apply() -> void:
	rage = 0
	manager.s_gags_chosen.connect(on_gags_chosen)
	manager.s_participant_joined.connect(participant_joined)
	manager.s_participant_will_die.connect(guydied)
	BattleService.s_toon_dealt_damage.connect(redirect_damage)
	BattleService.s_toon_dealt_damage.connect(on_toon_damage)
	manager.s_status_effect_added.connect(on_status_added)
	
	var user: Cog = target
	for cog in manager.cogs:
		if not user == cog:
			apply_to_cog(cog)


func cleanup() -> void:
	if manager.s_round_started.is_connected(on_gags_chosen):
		manager.s_round_started.disconnect(on_gags_chosen)
	if manager.s_participant_joined.is_connected(participant_joined):
		manager.s_participant_joined.disconnect(participant_joined)
	if BattleService.s_toon_dealt_damage.is_connected(redirect_damage):
		BattleService.s_toon_dealt_damage.disconnect(redirect_damage)
	if BattleService.s_toon_dealt_damage.is_connected(on_toon_damage):
		BattleService.s_toon_dealt_damage.disconnect(on_toon_damage)		
	if manager.s_status_effect_added.is_connected(on_status_added):
		manager.s_status_effect_added.disconnect(on_status_added)
	if manager.s_participant_will_die.is_connected(guydied):
		manager.s_participant_will_die.disconnect(guydied)

func renew() -> void:
	rage+= 10
	if not enraged and rage > 100:
		get_enraged()
	elif enraged:
		if rage_turns == 0:
			reapply_boost()
			sheild_up()
		rage_turns -= 1
	change_status_name()
	
func on_toon_damage(_action: BattleAction, cog: Node3D, amount: int) -> void:
	if not sheilds_up:
		return
	if target in _action.targets:
		rage += amount * 0.07



func on_status_added(status : StatusEffect) -> void:
	if status.target == target:
		if status.get_status_name() == "Lured" or status.get_status_name() == "Drenched":
			rage += 15
			
func on_gags_chosen(actions: Array[ToonAttack]) -> void:
	var ignored = true
	for action in actions:
		if target in action.targets:
			ignored = false
	if ignored:
		rage += 10

func get_enraged() -> void:
	enraged = true
	sheilds_up = false
	end_boost()
	if not desperation:
		var def_effect := STAT_BOOST_RESOURCE.duplicate()
		def_effect.target = target
		def_effect.boost = 1.5
		def_effect.stat = 'defense'
		def_effect.visible = true
		def_effect.rounds = 1
		def_effect.quality = StatusEffect.EffectQuality.POSITIVE
		def_effect.force_no_combine = true
		manager.add_status_effect(def_effect)	
	
	var attack_effect := STAT_BOOST_RESOURCE.duplicate()
	attack_effect.target = target
	attack_effect.boost = 1.3
	attack_effect.stat = 'attack'
	attack_effect.visible = false
	attack_effect.rounds = 1
	attack_effect.quality = StatusEffect.EffectQuality.POSITIVE
	attack_effect.force_no_combine = true

	manager.add_status_effect(attack_effect)
	if  not desperation:
		var lure_effect := ATTENTIVE_RESOURCE.duplicate()
		lure_effect.target = target
		lure_effect.rounds = 1
		manager.add_status_effect(lure_effect)
	else:
		var lure_effect := LURE_IMUN_RESOURCE.duplicate()
		lure_effect.target = target
		lure_effect.rounds = 1
		manager.add_status_effect(lure_effect)
	
	var cog = target
	var shield_attack: = Shield_Up_Attack.duplicate()
	shield_attack.user = cog
	shield_attack.targets = [cog]
	manager.round_end_actions.append(shield_attack) 

func sheild_up() -> void:
	enraged = false
	sheilds_up = true
	rage = 0
	rage_turns = 1
	
	var cog = target
	var shield_attack: = Shield_Up_Attack.duplicate()
	shield_attack.user = cog
	shield_attack.targets = [cog]
	shield_attack.rage = false
	manager.round_end_actions.append(shield_attack)

func participant_joined(who: Node3D) -> void:
	if who is Cog:
		apply_to_cog(who)

func apply_to_cog(cog: Cog) -> void:
	if not sheilds_up:
		return
	var new_boost := create_boost(cog)
	manager.add_status_effect(new_boost)
	boost_effects.append(new_boost)

func create_boost(who: Cog) -> StatBoost:
	var status_effect := STAT_BOOST_RESOURCE.duplicate()
	status_effect.target = who
	status_effect.boost = 1.515
	status_effect.stat = 'defense'
	status_effect.visible = true
	status_effect.rounds = -1
	status_effect.quality = StatusEffect.EffectQuality.NEUTRAL
	status_effect.force_no_combine = true
	return status_effect

func end_boost() -> void:
	for effect in boost_effects:
		if effect.target in manager.battle_stats.keys():
			manager.expire_status_effect(effect)
func reapply_boost() -> void:
	for cog in manager.cogs:
		if not target == cog:
			apply_to_cog(cog)
	
func redirect_damage(_action: BattleAction, cog: Node3D, amount: int):
	if not sheilds_up:
		return
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


func get_icon() -> Texture2D:
	if sheilds_up:
		return load("res://ui_assets/battle/statuses/scapegoat_shield.png")
	else: return load("res://ui_assets/battle/statuses/scapegoat_rage.png")

func get_description() -> String:
	var return_string := "i dont need the if but im not gonna change it, anyways hello code viewer"
	if sheilds_up:
		return_string = "Scapegoat's rage is building...
Scapegoat will absorb +30% of the damage dealt to other Cogs while in this mode!"
	elif not desperation: 
		return_string = "The Scapegoat is enraged!
Scapegoat will take -30% less damage and deal +30% more damage while in this mode!"
	else:
		return_string = "The Scapegoat is enraged!
Scapegoat will deal +30% more damage while in this mode!"
	return return_string
func change_status_name() -> void:
	if sheilds_up:
		status_name = "Rage Building: [%d%%]" % rage
	else:
		status_name = "Enraged"

func guydied(who: Node3D) -> void:
	if who is Cog and who != target:
		if who.dna.cog_name == "Scapegoat":
			return
		if who.dna.custom_nametag_suffix == "Director":
			desperation = true
			target.stats.damage *= 1.4
			var attack = PLACEHOLDER_ATTACK.duplicate()
			attack.battle_txt = true
			attack.battle_txt_string = "Desperation"
			attack.action_name = "  "
			attack.play_anim = false
			var attack_lines: Array[String] = [
	"...",
	"..."
]
			attack.attack_lines = attack_lines
			attack.user = target
			attack.targets = [target]
			manager.inject_battle_action(attack, 0)
