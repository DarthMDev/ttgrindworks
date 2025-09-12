extends Node3D
class_name ElevatorScene

const FLOOR_VARIANT_PATH := "res://scenes/game_floor/floor_variants/base_floors/"
const FINAL_FLOOR_VARIANT := preload("res://scenes/game_floor/floor_variants/alt_floors/final_boss_floor.tres")
const FINAL_FLOOR_VARIANT2 := preload("res://scenes/game_floor/floor_variants/alt_floors/final_boss_floor2.tres")
const ALT_FLOOR_CHANCE := 0


@onready var player_pos := $PlayerPosition
@onready var camera := $ElevatorCam
@onready var elevator := $Elevator

var player: Player
var next_floors: Array[FloorVariant] = []


func _ready():
	if Util.floor_number == 5:
		$ElevatorUI.arrow_left.hide()
		$ElevatorUI.arrow_right.hide()
	
	# Get the player in here or so help me
	player = Util.get_player()
	if not player:
		player = load('res://objects/player/player.tscn').instantiate()
		SceneLoader.add_persistent_node(player)
	player.game_timer_tick = false
	player.state = Player.PlayerState.STOPPED
	player.global_position = player_pos.global_position
	player.face_position(camera.global_position)
	player.scale = Vector3(2, 2, 2)
	player.set_animation('neutral')
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#if SaveFileService.run_file and SaveFileService.run_file.floor_choice:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#start_game_floor(SaveFileService.run_file.floor_choice)
		#return
	
	# Close the elevator doors
	elevator.animator.play('open')
	elevator.animator.seek(0.0)
	elevator.animator.pause()
	
	AudioManager.stop_music()
	AudioManager.set_default_music(load('res://audio/music/beta_installer.ogg'))
	
	# Save progress at every elevator scene
	await Task.delay(0.1)
	SaveFileService.save()
	
	# Get the next random floor
	get_next_floors()

func start_floor(floor_var: FloorVariant):
	#SaveFileService.run_file.floor_choice = floor_var
	#SaveFileService.save()
	elevator.animator.play('open')
	player.turn_to_position($Outside.global_position, 1.5)
	$ElevatorUI.hide()
	await camera.exit()
	
	start_game_floor(floor_var)

func start_game_floor(floor_var : FloorVariant) -> void:
	player.scale = Vector3(1, 1, 1)
	player.game_timer_tick = true
	if floor_var.override_scene:
		SceneLoader.change_scene_to_packed(floor_var.override_scene)
	else:
		var game_floor: GameFloor = load('res://scenes/game_floor/game_floor.tscn').instantiate()
		game_floor.floor_variant = floor_var
		SceneLoader.change_scene_to_node(game_floor)

## Selects  random floors to give to the player
func get_next_floors() -> void:
	if Util.floor_number == 5:
		final_boss_time_baby()
		return
	if Util.floor_number == 8:
		final_boss2_time_baby()
		return
	var random_floor_amount = 3
	var floor_variants = Globals.FLOOR_VARIANTS
	floor_variants = DirAccess.get_files_at(FLOOR_VARIANT_PATH)
	if Util.floor_number >= 3:
		floor_variants = [floor_variants[floor_variants.size() - 1]] #3 but it looks better than just 3
	elif Util.floor_number == 2:
		floor_variants.remove_at(floor_variants.size() - 1)
	var taken_items: Array[String] = []
	if Util.floor_number >= 3:
		add_normal_floor(floor_variants)
		add_positive_floor(floor_variants)
		random_floor_amount = 2
	for i in random_floor_amount:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		if Util.floor_number < 2:
			floor_variants.remove_at(floor_variants.find(random_floor))
		var new_floor = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		
		new_floor.randomize_details()
		while not new_floor.reward or new_floor.reward.item_name in taken_items:
			new_floor.randomize_item()
		if Util.floor_number < 3:
			new_floor.anomaly_rebalance(new_floor.reward.qualitoon,new_floor.floor_name)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		next_floors.append(new_floor)
		taken_items.append(new_floor.reward.item_name)
	add_more_floors(floor_variants)
	$ElevatorUI.floors = next_floors
	$ElevatorUI.set_floor_index(0)

func final_boss_time_baby() -> void:
	var final_floor := FINAL_FLOOR_VARIANT.duplicate()
	final_floor.level_range = Vector2i(13, 15)
	next_floors = [final_floor]
	$ElevatorUI.floors = next_floors
	$ElevatorUI.set_floor_index(0)
func final_boss2_time_baby() -> void:
	var final_floor2 := FINAL_FLOOR_VARIANT2.duplicate()
	final_floor2.level_range = Vector2i(20, 24)
	next_floors = [final_floor2]
	$ElevatorUI.floors = next_floors
	$ElevatorUI.set_floor_index(0)

func _exit_tree() -> void:
	if Util.get_player():
		Util.get_player().game_timer_tick = true
func add_more_floors(floor_variants) -> void:
	if Util.floor_number >= 2:
		if Util.floor_number < 6: add_chaos_floor(floor_variants)
		add_gag_immune_floor(floor_variants)
		if Util.floor_number >= 3:
			add_mixed_bag_floor(floor_variants)
		if Util.floor_number >= 7:  #make 7
			add_huoftf_floor(floor_variants)


func add_gag_immune_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_gag_immunity_anomaly()
		anom_array = try_add_unstable_core_anom(new_floor, anom_array)
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		if Util.floor_number == 2: new_floor.anomaly_rebalance_on_set_anoms(new_floor.reward.qualitoon,new_floor.floor_name)
		next_floors.append(new_floor)
			
func add_chaos_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		if Util.floor_number == 2:
			random_floor = floor_variants[1] # da office maybe
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.all_negative_anomalies()
		if Util.floor_number >= 6:
			#anom_array = try_add_unstable_core_anom(new_floor, anom_array)
			print("bruh what?")
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Survive The Foremen"
		while not new_floor.reward:
			new_floor.randomize_good_item()
		next_floors.append(new_floor)
func add_normal_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_no_anomaly()
		anom_array = try_add_unstable_core_anom(new_floor, anom_array)
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)
func add_reorg_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_reorg_anomaly()
		anom_array = try_add_unstable_core_anom(new_floor, anom_array)
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)

func add_mixed_bag_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_mixed_bag_anomaly()
		anom_array = try_add_unstable_core_anom(new_floor, anom_array)
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)
func add_larynx_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_larynx_anomaly()
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The 🗣"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)

func add_annoying_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_annoying_anomaly()
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)

func add_huoftf_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.get_highly_unstable_anomaly()
		new_floor.scripted_details(anom_array)
		new_floor.floor_name = "Highly Unstable Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.randomize_item()
		next_floors.append(new_floor)


func add_positive_floor(floor_variants) -> void:
		var random_floor = floor_variants[RandomService.randi_channel('floors') % floor_variants.size()]
		var new_floor: FloorVariant = Util.universal_load(FLOOR_VARIANT_PATH + random_floor).duplicate()
		var anom_array = new_floor.all_positive_anomalies()
		anom_array = try_add_unstable_core_anom(new_floor, anom_array)
		new_floor.scripted_details(anom_array)
		if Util.floor_number >= 3: new_floor.floor_name = "Overclocked Fight The Foremen"
		while not new_floor.reward:
			new_floor.get_snowflake()
		next_floors.append(new_floor)

func try_add_unstable_core_anom(new_floor: FloorVariant,anom_array) -> Array:
	if Util.floor_number >= 6:
		anom_array = new_floor.add_unstable_core(anom_array)
	return anom_array
