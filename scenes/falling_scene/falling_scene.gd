extends Node3D

var GAME_FLOOR: PackedScene
var INTRO_STINGER: AudioStreamOggVorbis

@export var gags: Array[PackedScene]
@export var camera_final_y: float = 100.0
@export var gag_limit := 200

## Child References
@onready var toon := $Props/Toon
@onready var camera := $Camera
@onready var props := $Props
@onready var logo := $SceneUI/Logo

## Locals
var scene_ending := false

func _init():
	GameLoader.queue_into(GameLoader.Phase.FALLING_SEQ, self, {
		'INTRO_STINGER': 'res://audio/music/intro_stinger.ogg'
	})
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'GAME_FLOOR': 'res://scenes/game_floor/game_floor.tscn'
	})

func _ready() -> void:
	AudioManager.stop_music(true)
	#AudioManager.play_sound(load('res://audio/sfx/battle/gags/drop/incoming_whistleALT.ogg'))
	var dna : ToonDNA
	if not is_instance_valid(Util.get_player()):
		dna = ToonDNA.new()
		dna.randomize_dna()
	else:
		dna = Util.get_player().toon.toon_dna
		Util.get_player().hide()
		Util.get_player().stats.hp = Util.get_player().stats.max_hp
	AudioManager.play_sound(Globals.get_species_sfx(Globals.ToonDial.FALLING,dna))
	toon.construct_toon(dna)
	toon.scale *= 5.0
	toon.set_animation('melt-nosink')
	toon.body.animator.seek(1.8)
	toon.body.animator.play()
	toon.set_emotion(Toon.Emotion.SURPRISE)
	toon.reset_physics_interpolation()
	try_add_accessories()
	var twoon := toon.create_tween()
	twoon.tween_property(toon, 'scale', Vector3.ONE * 0.01, 5.0)
	animate_toon()
	do_gag_creation()
	await move_camera()
	end_scene()

func try_add_accessories() -> void:
	var items := Util.get_player().stats.character.starting_items
	var hat: ItemAccessory
	var glasses: ItemAccessory
	var backpack: ItemAccessory
	var shoes: ItemShoe
	for item in items:
		if item is ItemAccessory:
			match item.slot:
				Item.ItemSlot.HAT: hat = item
				Item.ItemSlot.GLASSES: glasses = item
				Item.ItemSlot.BACKPACK: backpack = item
		elif item is ItemShoe:
			shoes = item
	for accessory in [hat, glasses, backpack]:
		if accessory:
			accessory.place_accessory(toon)
	if shoes:
		shoes.place_shoes(toon)

func animate_toon() -> void:
	while true:
		await toon.body.animator.animation_finished
		toon.body.animator.speed_scale = -1.0
		toon.body.animator.seek(2.3)
		toon.body.animator.play()
		await Task.delay(0.5)
		toon.body.animator.speed_scale = 1.0
		toon.body.animator.play()

func do_gag_creation() -> void:
	var delay := 0.25
	var min_delay := 0.025
	var gags_to_drop := 80
	var gag_count := 0
	var step := 0.01
	while not scene_ending and gag_count < gags_to_drop:
		await Task.delay(delay)
		gag_count +=1
		create_random_gag(0.0-(float(gag_count))*0.25)
		delay-=step
		delay = max(delay,min_delay)

func move_camera() -> void:
	var cam_tween := create_tween()
	cam_tween.set_parallel(true)
	cam_tween.set_trans(Tween.TRANS_SINE)
	cam_tween.tween_property(camera, 'position:y', camera_final_y, 5.0)
	cam_tween.tween_property(toon, 'rotation_degrees', Vector3(60, 120, 90), 5.0)
	if Util.get_player():
		cam_tween.tween_property(Util.get_player().stats, 'max_hp', Util.get_player().stats.character.starting_laff, 5.0)
		cam_tween.tween_property(Util.get_player().stats, 'hp', Util.get_player().stats.character.starting_laff, 5.0)
	await cam_tween.finished
	toon.hide()
	scene_ending = true
	await show_logo()

func show_logo() -> void:
	play_intro_stinger()
	var zoom_tween := create_tween()
	zoom_tween.tween_property(logo, 'scale', Vector2(0.33, 0.33), 10.0)
	var color_tween := create_tween()
	color_tween.tween_property(logo, 'self_modulate', Color('ffffff'), 2.25)
	color_tween.tween_interval(4.7)
	color_tween.tween_property(logo, 'self_modulate', Color('ffffff00'), 0.1)
	await zoom_tween.finished
	zoom_tween.kill()
	color_tween.kill()

func play_intro_stinger() -> void:
	var stinger_player := AudioManager.play_sound(INTRO_STINGER)
	stinger_player.bus = "Music"
	stinger_player.seek(2.0)

func create_random_gag(volume := 0.0) -> void:
	if gags.is_empty():
		return
	AudioManager.play_sound(load('res://audio/sfx/ui/tick_counter.ogg'),volume)
	var model: Node3D = gags.pick_random().instantiate()
	props.add_child(model)
	model.scale /= 20.0
	model.global_position = toon.global_position
	var fall_time := randf() * 1.0 + 2.0
	var gag_tween := create_tween()
	gag_tween.set_parallel(true)
	gag_tween.set_trans(Tween.TRANS_QUINT)
	gag_tween.tween_property(model, 'global_position:y', camera_final_y + 20.0, fall_time)
	gag_tween.tween_property(model, 'global_position:x', camera.global_position.x + randf_range(-20.0, 20.0), fall_time)
	gag_tween.tween_property(model, 'global_position:z', camera.global_position.z + randf_range(-20.0, 20.0), fall_time)
	gag_tween.tween_property(model, 'rotation_degrees', Vector3(randi() % 360,
		randi() % 360,
		randi() % 360),
		randi() * fall_time)
	gag_tween.tween_property(model, 'scale', Vector3(1.0 ,1.0, 1.0), fall_time).as_relative()
	gag_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	gag_tween.finished.connect(func(): 
		gag_tween.kill() 
		model.queue_free()
		)

func end_scene() -> void:
	if is_instance_valid(Util.get_player()):
		await GameLoader.wait_for_phase(GameLoader.Phase.GAMEPLAY)
		Util.get_player().show()
		Util.get_player().reset_stats()
		Util.get_player().stats.initialize_quests()
		Util.get_player().lock_game_timer = false
		Globals.s_game_started.emit()
		var gamefloor := GAME_FLOOR.instantiate()
		gamefloor.floor_variant = get_first_floor()
		SceneLoader.change_scene_to_node(gamefloor)
	else:
		SceneLoader.change_scene_to_file('res://scenes/falling_scene/falling_scene.tscn')

# Make a custom floor variant for first floor
func get_first_floor() -> FloorVariant:
	var floor_var: FloorVariant = RNG.channel(RNG.ChannelFloors).pick_random(Globals.FLOOR_VARIANTS).duplicate(true)
	# Guarantee 0 difficulty floor to start
	floor_var.floor_difficulty = 0
	floor_var.randomize_details(Util.get_player().stats.anomaly_boost > 0)
	floor_var.reward = null
	
	return floor_var
