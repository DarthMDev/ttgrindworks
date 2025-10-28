extends ItemScriptActive

const DEFLECT_TIME_MIN := 0.3
const DEFLECT_COLOR := Color(0.466, 0.663, 0.935)

var potential_deflected_attack: CogAttack
var attack_was_deflected := false
var attack_accounted_for := false
var deflect_damage: int:
	get:
		if potential_deflected_attack:
			return ceili((potential_deflected_attack.damage + 2) * 1.5)
		return 1

var player: Player:
	get: return Util.get_player()

func validate_use() -> bool:
	if not BattleService.ongoing_battle:
		return false
	var action: BattleAction = BattleService.ongoing_battle.current_action
	if not action:
		return false
	if not (action is CogAttack and player in action.targets):
		return false
	if action.damage <= 0:  # Cancels on non-damage attacks and on heals
		return false
	if potential_deflected_attack or attack_was_deflected:
		return false
	if attack_accounted_for:
		return false
	if action.has_tag(BattleAction.ActionTag.NULLIFY_DISABLED):
		return false
	return true

func use() -> void:
	var action: BattleAction = BattleService.ongoing_battle.current_action
	attack_accounted_for = true
	action.nullified = true
	potential_deflected_attack = action
	var deflect_time := get_deflect_time()
	player.toon.color_overlay_mat.flash_instant_fade(player, DEFLECT_COLOR, deflect_time, 0.7)
	AudioManager.play_sound(load("res://audio/sfx/items/laff_boost_pickup.ogg"))

	await Task.delay(deflect_time)

	check_deflect_fail()

func get_deflect_time() -> float:
	var deflect_time := DEFLECT_TIME_MIN
	var evasiveness: float = Util.get_relevant_player_stats().get_stat('evasiveness')
	var evasiveness_boost := maxf(0.0, (evasiveness - 1.0) * 0.5)
	deflect_time += evasiveness_boost
	return deflect_time

func _on_battle_started(battle: BattleManager) -> void:
	super(battle)
	battle.s_action_finished.connect(_action_finished)
	battle.s_target_nullified_action.connect(_attack_nullified)

func _action_finished(_action: BattleAction) -> void:
	check_deflect_fail()
	potential_deflected_attack = null
	attack_was_deflected = false
	attack_accounted_for = false

func check_deflect_fail() -> void:
	# We will only still have one if it hasn't been deflected by now
	if (not potential_deflected_attack) or attack_was_deflected:
		return

	if BattleService.ongoing_battle and BattleService.ongoing_battle.current_action == potential_deflected_attack:
		var battle: BattleManager = BattleService.ongoing_battle
		if potential_deflected_attack not in battle.action_hit_rolls:
			battle.action_hit_rolls[potential_deflected_attack] = true

		if battle.action_hit_rolls[potential_deflected_attack]:
			var oldman_deflected := false
			if potential_deflected_attack.has_tag(BattleAction.ActionTag.OLDMAN_NULLIFY):
				oldman_deflected = true
			else:
				potential_deflected_attack.nullified = false
			player.boost_queue.queue_text("Parry Fail!", Color(1.0, 0.287, 0.225))
			potential_deflected_attack.damage = deflect_damage
			AudioManager.play_snippet(load("res://audio/sfx/battle/gags/drop/AA_drop_flowerpot_miss.ogg"), 0.32, -1.0, 5.0)
			if player.revives_are_hp and not oldman_deflected:
				# Take an additional HP loss on a failed deflect on a revives-only character
				potential_deflected_attack.add_tag(BattleAction.ActionTag.DOUBLE_REVIVE_DAMAGE)

	potential_deflected_attack = null
	attack_was_deflected = false

func _attack_nullified(_target: Node3D, action: BattleAction) -> void:
	if action != potential_deflected_attack:
		return

	# Make a new deflect attack to apply the damage
	var new_action := ActionScriptCallable.new()
	new_action.callable = hurt_cog
	new_action.add_tag(BattleAction.ActionTag.IS_DEFLECT_ATTACK)
	new_action.user = BattleService.ongoing_battle.battle_node
	new_action.targets = [potential_deflected_attack.user]
	new_action.damage = ceili(deflect_damage * player.stats.get_stat('damage'))
	BattleService.ongoing_battle.inject_battle_action(new_action, 0)

	potential_deflected_attack = null
	attack_was_deflected = true
	player.boost_queue.queue_text("Parried!", DEFLECT_COLOR)
	AudioManager.play_sound(load("res://audio/sfx/battle/gags/crit/crit_2.ogg"), 7.0)

func hurt_cog() -> void:
	var manager := BattleService.ongoing_battle
	var battle_node := manager.battle_node
	var targets := manager.current_action.targets
	var damage: int = manager.current_action.damage
	
	manager.show_action_name("Parried Damage!")
	var cog: Cog = targets[0]
	BattleService.ongoing_battle.battle_node.focus_character(cog)
	cog.set_animation('pie-small')
	manager.affect_target(cog, damage)
	AudioManager.play_sound(load("res://audio/sfx/battle/cogs/attacks/special/tt_s_ara_cfg_toonHit.ogg"))
	await Task.delay(3.0)
	
	await manager.check_pulses(targets)
