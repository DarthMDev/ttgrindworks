extends ItemScriptActive

const SFX_PRESS := preload("res://audio/sfx/battle/gags/AA_trigger_box.ogg")
const BUTTON := preload("res://models/props/gags/button/toon_button.tscn")
const HAMMER := preload("res://models/props/toon_props/toy_hammer/hammer_animated.tscn")
const DROP_SHADOW := preload("res://objects/misc/drop_shadow/drop_shadow.tscn")
const SFX_FALL := preload("res://audio/sfx/battle/gags/drop/incoming_whistleALT.ogg")
const SFX_HIT := preload("res://audio/sfx/items/clock05.ogg")

func use() -> void:
	var player := Util.get_player()
	var battles := get_all_battles()
	if not player.is_on_floor() or battles.is_empty():
		cancel_use()
		return
	
	var cogs: Array[Cog] = []
	for battle in battles:
		cogs.append_array(battle.cogs)
	
	player.set_collision_layer_value(Globals.PLAYER_COLLISION_LAYER, false)
	var tween := make_tween(player, cogs)
	await tween.finished
	tween.kill()
	player.set_collision_layer_value(Globals.PLAYER_COLLISION_LAYER, true)
	player.state = Player.PlayerState.WALK

func make_tween(player: Player, cogs: Array[Cog]) -> Tween:
	var button := BUTTON.instantiate()
	
	player.toon.left_hand_bone.add_child(button)
	player.state = Player.PlayerState.STOPPED
	
	var tween := create_tween()
	tween.tween_callback(player.set_animation.bind('button_press'))
	tween.tween_interval(2.3)
	tween.tween_callback(AudioManager.play_sound.bind(SFX_PRESS))
	
	for cog in cogs:
		tween.tween_callback(demote_cog.bind(cog))
	
	tween.tween_interval(3.0)
	tween.finished.connect(button.queue_free)
	return tween

func get_all_battles() -> Array[BattleNode]:
	var node: Node
	if is_instance_valid(Util.floor_manager):
		node = Util.floor_manager.get_current_room()
	else:
		node = SceneLoader
	return search_node(node)

func search_node(node : Node) -> Array[BattleNode]:
	var battles : Array[BattleNode] = []
	for child in node.get_children():
		if child is BattleNode:
			if child.monitoring and not child.override_intro:
				battles.append(child)
		else:
			battles.append_array(search_node(child))
	return battles

func demote_cog(cog: Cog) -> void:
	var drop_shadow := DROP_SHADOW.instantiate()
	drop_shadow.scale *= 0.01
	drop_shadow.position.y += 0.05
	cog.add_child(drop_shadow)
	var prop := HAMMER.instantiate()
	
	var demote_tween := create_tween()
	demote_tween.tween_callback(AudioManager.play_sound.bind(SFX_FALL, -10.0))
	demote_tween.tween_property(drop_shadow, 'scale', Vector3.ONE * 1.5, 2.0)
	demote_tween.tween_callback(AudioManager.play_sound.bind(SFX_HIT))
	demote_tween.tween_callback(lower_cog_level.bind(cog))
	demote_tween.tween_callback(cog.set_animation.bind('anvil-drop'))
	demote_tween.tween_callback(parent_prop.bind(cog, prop))
	demote_tween.tween_callback(prop.get_node('AnimationPlayer').play.bind('drop'))
	demote_tween.tween_callback(drop_shadow.queue_free)
	demote_tween.tween_interval(3.0)
	demote_tween.finished.connect(
	func():
		demote_tween.kill()
		prop.queue_free()
	)

func parent_prop(cog: Cog, prop: Node3D) -> void:
	cog.body.add_child(prop)
	prop.global_position = cog.body.head_bone.global_position
	prop.position.y -= (1.0 if cog.dna.suit == CogDNA.SuitType.SUIT_C else 2.0)

func lower_cog_level(cog: Cog) -> void:
	Util.do_3d_text(cog, "Level Down!")
	if cog.dna.cog_name == "Mad Hander":
		pass
	# Undo DNA health mod change
	if not is_equal_approx(cog.dna.health_mod, 1.0):
		cog.health_mod /= cog.dna.health_mod
	# Undo Mod Cog DNA Change
	if cog.dna.is_mod_cog:
		cog.health_mod /= Util.get_mod_cog_health_mod()
	var cog_is_fusion := cog.fusion
	cog.fusion = false
	cog.level = maxi(1, cog.level - 3)
	cog.set_dna(cog.dna, false)
	if cog_is_fusion:
		cog.fusion = true
