extends ItemScript


var player: Player:
	get: return Util.get_player()

func on_collect(_item: Item, _model) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_action_started.connect(on_action_start)
	player.stats.max_hp_changed.connect(on_max_hp_change)
	BattleService.s_battle_started.connect(_on_battle_started)

func _on_battle_started(battle: BattleManager) -> void:
	battle.s_target_nullified_action.connect(_attack_nullified)

func _attack_nullified(participant: Node3D, action: BattleAction) -> void:
	if participant == player and action.has_tag(BattleAction.ActionTag.OLDMAN_NULLIFY):
		player.boost_queue.queue_text("Deflected!", Globals.dna_colors["slate_blue"].lerp(Color.WHITE, 0.5))
		AudioManager.play_sound(load("res://audio/sfx/battle/gags/crit/crit_2.ogg"), 7.0)

func on_action_start(action: BattleAction) -> void:
	if not (action is CogAttack and player in action.targets):
		return
	var attack: CogAttack = action
	
	if attack.damage <= 0:  # Cancels on non-damage attacks and on heals
		return
	
	if not roll_for_deflect(attack) or not BattleService.ongoing_battle.roll_for_accuracy(attack):
		return
	
	attack.nullified = true
	attack.add_tag(BattleAction.ActionTag.OLDMAN_NULLIFY)
	var new_action := ActionScriptCallable.new()
	new_action.callable = hurt_cog
	new_action.add_tag(BattleAction.ActionTag.IS_DEFLECT_ATTACK)
	new_action.user = BattleService.ongoing_battle.battle_node
	new_action.targets = [attack.user]
	new_action.damage = attack.damage
	BattleService.ongoing_battle.inject_battle_action(new_action, 0)

func roll_for_deflect(attack: CogAttack) -> bool:
	if attack.has_tag(BattleAction.ActionTag.NULLIFY_DISABLED):
		return false

	var deflect_chance := 0.1 + ((player.stats.defense - 1.0) * 0.25)
	return randf() < deflect_chance

func on_max_hp_change(_new_hp: int) -> void:
	var scene_current := SceneLoader.current_scene.name
	if scene_current == 'FallingScene' or scene_current == 'TitleScreen':
		return
	await get_tree().process_frame
	if player.stats.max_hp > 1:
		var diff := player.stats.max_hp - 1
		player.stats.max_hp = 1
		player.stats.hp = 1
		player.stats.extra_lives += diff
	elif player.stats.max_hp < 1:
		player.stats.max_hp = 1
		player.stats.hp = 1

func hurt_cog() -> void:
	var manager := BattleService.ongoing_battle
	var battle_node := manager.battle_node
	var targets := manager.current_action.targets
	var damage: int = manager.current_action.damage
	
	manager.show_action_name("Deflected Damage!")
	var cog: Cog = targets[0]
	BattleService.ongoing_battle.battle_node.focus_character(cog)
	cog.set_animation('pie-small')
	manager.affect_target(cog, damage)
	AudioManager.play_sound(load("res://audio/sfx/battle/cogs/attacks/special/tt_s_ara_cfg_toonHit.ogg"))
	await Task.delay(3.0)
	
	await manager.check_pulses(targets)
	
