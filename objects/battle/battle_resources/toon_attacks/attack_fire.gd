extends ToonAttack
class_name ToonAttackFire

const CANNON := preload('res://objects/props/etc/cannon/fire_cannon.tscn')
const BUTTON := preload("res://models/props/gags/button/toon_button.tscn")

const SFX_PANIC := preload("res://audio/sfx/battle/gags/ENC_cogafssm.ogg")
const SFX_WHISTLE := preload("res://audio/sfx/battle/gags/firework_whistle_01.ogg")
const SFX_ADJUST := preload("res://audio/sfx/battle/gags/MG_cannon_adjust.ogg")
const SFX_FIRE := preload("res://audio/sfx/battle/gags/MG_cannon_fire_alt.ogg")
const SFX_PRESS := preload("res://audio/sfx/battle/gags/AA_trigger_box.ogg")


func action() -> void:
	# Get some initial values
	var cog : Cog = targets[0]
	var cannon := CANNON.instantiate()
	var player : Player = user
	var dust_cloud = Globals.DUST_CLOUD.instantiate()
	
	# Cheat v2.0s
	cog.v2 = false
	
	# Player hits switch
	player.set_animation('button_press')
	player.face_position(cog.global_position)
	battle_node.focus_character(player)
	
	# Place button in hand
	var button := BUTTON.instantiate()
	player.toon.left_hand_bone.add_child(button)
	
	# Play press sfx
	await manager.sleep(2.3)
	AudioManager.play_sound(SFX_PRESS)
	await manager.sleep(0.2)
	button.queue_free()
	
	# Miss on tenured Cogs
	if cog_has_tenure(cog):
		await miss(cog)
		return
	
	# Bring cannon in
	set_camera_angle('SIDE_RIGHT')
	manager.battle_text(cog,str(-cog.stats.hp))
	cog.stats.hp = 0
	battle_node.add_child(cannon)
	cannon.global_position = cog.global_position
	cannon.global_rotation = cog.global_rotation
	cog.reparent(cannon.get_node('cannon/toon_cannon/cannon/CogPos'))
	
	# Create the Cannon Tween
	var cannon_tween := cannon.create_tween()
	
	# Raise cannon, and shrink cog into position
	cannon_tween.set_parallel(true)
	cannon_tween.tween_callback(AudioManager.play_sound.bind(SFX_PANIC))
	cannon_tween.tween_callback(cog.set_animation.bind('flailing'))
	cannon_tween.tween_property(cannon.get_node('cannon'),'position:y',0.0,1.0)
	cannon_tween.tween_property(cog,'scale',Vector3(1,1,1),1.0)
	cannon_tween.tween_property(cog,'position',Vector3(0,0,0),1.0)
	if cog.lured:
		cannon_tween.tween_property(cog.body_root,'position:z',0.0,1.0)
	cannon_tween.set_parallel(false)
	cannon_tween.tween_interval(1.0)
	
	# Rotate cannon to fire position
	cannon_tween.tween_callback(player.set_animation.bind('duck'))
	cannon_tween.tween_callback(AudioManager.play_sound.bind(SFX_ADJUST))
	cannon_tween.tween_property(cannon.get_node('cannon/toon_cannon/cannon'),'rotation_degrees:x',145.0,1.25)
	cannon_tween.tween_interval(1.5)
	
	# Fire the cog out of the cannon
	cannon_tween.tween_callback(cannon.get_node('cannon/toon_cannon/cannon/CogPos').add_child.bind(dust_cloud))
	cannon_tween.tween_callback(dust_cloud.set_as_top_level.bind(true))
	cannon_tween.tween_callback(dust_cloud.set_scale.bind(Vector3(1,1,1)))
	cannon_tween.tween_callback(AudioManager.play_sound.bind(SFX_FIRE))
	cannon_tween.tween_callback(AudioManager.play_sound.bind(SFX_WHISTLE))
	cannon_tween.tween_property(cannon.get_node('cannon/toon_cannon/cannon/CogPos'),'position:y',100.0,1.0)
	cannon_tween.tween_callback(cannon.queue_free)
	await cannon_tween.finished
	
	# Remove cog from battle
	manager.someone_died(cog)

func miss(cog : Cog) -> void:
	var miss_tween := manager.create_tween()
	miss_tween.tween_callback(battle_node.focus_character.bind(cog))
	miss_tween.tween_callback(manager.battle_text.bind(cog, 'MISSED'))
	miss_tween.tween_callback(cog.speak.bind("You have no grounds to fire me."))
	miss_tween.tween_interval(3.0)
	await miss_tween.finished
	miss_tween.kill()

const TENURE_STATUS := "res://objects/battle/battle_resources/status_effects/resources/tenure_status.tres"
func cog_has_tenure(cog: Cog) -> bool:
	return cog.dna.status_effects.has(load(TENURE_STATUS))

func get_stats() -> String:
	return "Pink Slips: " + str(Util.get_player().stats.pink_slips)
