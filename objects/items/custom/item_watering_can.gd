extends ItemScriptActive

const FLOWER_MODEL := "res://models/props/toon_props/flowers/daisy/daisy.tscn"
const LAFF_LEECH_EFFECT := "res://objects/battle/battle_resources/status_effects/resources/status_effect_laff_leech.tres"

func use() -> void:
	for cog in BattleService.ongoing_battle.cogs:
		apply_status(cog)
	
	BattleService.ongoing_battle.battle_ui.cog_panels.reset(0)
	BattleService.ongoing_battle.battle_ui.cog_panels.assign_cogs(BattleService.ongoing_battle.cogs)
	
	cutscene()

func cutscene() -> void:
	# Setup
	var battle: BattleManager = BattleService.ongoing_battle
	var bnode: BattleNode = battle.battle_node
	var ui: BattleUI = battle.battle_ui
	var player: Player = Util.get_player()
	if is_instance_valid(ui.timer):
		ui.timer.timer.set_paused(true)
	ui.hide()
	player.toon.hide()
	
	# Actual cutscene
	bnode.focus_cogs()
	bnode.battle_cam.position.z += 1
	var flower_scale_tween := create_tween().set_parallel()
	for cog: Cog in bnode.cogs: 
		var flower: Node3D = load(FLOWER_MODEL).instantiate()
		cog.body.head_bone.add_child(flower)
		flower.scale = Vector3.ONE * 0.01
		flower.position = Vector3(0, 0.0, 1.0)
		flower.rotation.x = 90.0
		flower_scale_tween.tween_property(flower, 'scale', Vector3.ONE * 8.0, 1.0)
	flower_scale_tween.finished.connect(flower_scale_tween.kill)
	
	# Do cog anim
	await Task.delay(0.5)
	for cog in battle.cogs:
		cog.set_animation('soak')
	await Task.delay(2.0)
	for cog in battle.cogs:
		cog.set_animation('neutral')
	
	# Cleanup
	if is_instance_valid(ui.timer):
		ui.timer.timer.set_paused(false)
	ui.show()
	player.toon.show()
	bnode.focus_character(bnode)

func apply_status(cog: Cog) -> void:
	var effect: StatusEffect = load(LAFF_LEECH_EFFECT).duplicate(true)
	effect.heal_perc = 0.05
	effect.target = cog
	BattleService.ongoing_battle.add_status_effect(effect)
