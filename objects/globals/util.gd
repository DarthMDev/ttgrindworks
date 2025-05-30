extends Node

var CIRCLE_TRANSITION: PackedScene
var LOSE_MENU: PackedScene

# Global Refs
var player : Player:
	set(x):
		player = x
		s_player_assigned.emit(x)
		player.s_died.connect(on_player_died)
var floor_manager : GameFloor:
	set(x):
		floor_manager = x
		if x == null:
			return
		s_floor_started.emit(x)
		# Mirror the game floor's end signal with a globally accessible version
		# And null out the reference once the floor ends
		x.s_floor_ended.connect(
		func(): 
			s_floor_ended.emit()
			floor_manager = null
		)
var lose_menu: LoseMenu = null
var stored_try_again_char_name: String = ""
## Set to true when player should not be allowed to click the "I'm Stuck" button
var stuck_lock := false
var random_stats : PlayerStats

signal s_process_frame
signal s_player_assigned(player: Player)
signal s_floor_started(game_floor: GameFloor)
signal s_floor_ended
signal s_player_died
signal s_fullscreen_toggled(fullscreen: bool)
signal s_floor_number_changed

var floor_type : DepartmentFloor
var window_focused := true
var stop_camera_shake := false

var floor_number := -1:
	set(x):
		floor_number = x
		s_floor_number_changed.emit()

func get_player() -> Player:
	return player

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			window_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			window_focused = true

# Utilities to always run in the background
func _process(_delta):
	# Don't let the mouse be captured when window is unfocused
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not window_focused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed('fullscreen'):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var fullscreen : bool =  DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	SaveFileService.settings_file.fullscreen = fullscreen
	s_fullscreen_toggled.emit(fullscreen)
	

func do_3d_text(node: Node3D, text: String, text_color: Color = Color('ff0000'), outline_color: Color = Color('7a0000')) -> BattleText:
	var obj: BattleText = load('res://objects/battle/3d_text/3d_text.tscn').instantiate()
	obj.text = text
	obj.modulate = text_color
	obj.outline_modulate = outline_color
	node.add_child(obj)
	return obj

func _init():
	GameLoader.queue_into(
		GameLoader.Phase.GAME_START, self, {
			'CIRCLE_TRANSITION': 'res://objects/general_ui/circle_transition/circle_transition.tscn',
			'CONFIRM_PANEL': 'res://objects/general_ui/ui_panel/confirm_panel.tscn',
		}
	)
	GameLoader.queue_into(
		GameLoader.Phase.GAMEPLAY, self, {
			'LOSE_MENU': 'res://objects/player/ui/lose_menu.tscn',
		}
	)

func _ready():
	get_tree().process_frame.connect(func(): s_process_frame.emit())

## Show an acknowledge panel to the player
func acknowledge(text: String, button_text := "Okay", title_text := "") -> UIPanel:
	var panel: UIPanel = load('res://objects/general_ui/ui_panel/acknowledge_panel.tscn').instantiate()
	
	panel.ready.connect(func(): 
		panel.body = text
		panel.title = title_text
		panel.get_node('Panel/ConfirmButton').text = button_text
	)
	
	get_tree().get_root().add_child(panel)
	
	return panel

var CONFIRM_PANEL: PackedScene
func confirm(title : String, body := "", confirm_text := "Confirm", cancel_text := "Cancel") -> UIPanel:
	var panel := CONFIRM_PANEL.instantiate()
	get_tree().get_root().add_child(panel)
	panel.title = title
	panel.body = body
	panel.confirm_button.text = confirm_text
	panel.canceled_button.text = cancel_text
	return panel

func get_cog_head_icon(dna : CogDNA) -> Texture2D:
	var head := dna.get_head()
	return await get_ortho_model_tex(head)

func get_ortho_model_tex(model : Variant) -> Texture2D:
	var true_mod: Node3D
	if model is PackedScene:
		true_mod = model.instantiate()
	elif model is Node3D:
		true_mod = model
	else:
		return null
	
	# Create a model viewer and hide it by making it transparent
	var viewer : TextureRect = load('res://objects/general_ui/model_viewer/model_viewer.tscn').instantiate()
	add_child(viewer)
	viewer.self_modulate.a = 0.0
	viewer.get_node('SubViewport').add_child(true_mod)
	
	# Get the first mesh instance under model
	for child in true_mod.get_children():
		if child is MeshInstance3D:
			viewer.model = child
			viewer.adjust_cam()
	
	# Await 3 frames to allow texture to be drawn to
	# Any lower than this can yield some weird results
	for i in 3:
		await s_process_frame
	
	# Generate the texture
	var tex := ImageTexture.create_from_image(viewer.texture.get_image())
	
	# Free the viewer and return texture
	viewer.queue_free()
	return tex

func on_easy_floor() -> bool:
	return floor_number < 3

## Creates a timer
func run_timer(time := 5.0, anchor := Control.PRESET_BOTTOM_RIGHT) -> GameTimer:
	var timer: GameTimer = load('res://objects/battle/misc_battle_objects/timer/battle_timer.tscn').instantiate()
	get_tree().get_root().add_child(timer)
	timer.set_anchors_and_offsets_preset(anchor,Control.PRESET_MODE_KEEP_SIZE)
	if anchor == Control.PRESET_BOTTOM_RIGHT:
		timer.position.y -= 40
	timer.start(time)
	# Make sure the timer goes away whenever it needs to
	s_player_died.connect(timer.queue_free, CONNECT_ONE_SHOT)
	s_floor_ended.connect(timer.queue_free, CONNECT_ONE_SHOT)
	return timer

func get_hazard_damage(damage := 0) -> int:
	var true_damage := damage + (-(floor_number + 1) * 2)
	if is_instance_valid(floor_manager):
		if floor_manager.floor_tags.has('extra_hazard_damage') and floor_manager.floor_tags['extra_hazard_damage'] == true:
			true_damage = floori(1.25 * true_damage)
	return true_damage

func circle_in(time : float) -> void:
	var circle: CircleTransition = CIRCLE_TRANSITION.instantiate()
	get_tree().get_root().add_child(circle)
	circle.open(time)

func universal_load(file_path : String) -> Variant:
	if '.remap' in file_path:
		file_path = file_path.trim_suffix('.remap')
	return load(file_path)

func file_exists(file_path : String) -> bool:
	if file_path.begins_with('res://'):
		if not FileAccess.file_exists(file_path + '.remap'):
			return FileAccess.file_exists(file_path)
		else:
			return FileAccess.file_exists(file_path + '.remap')
	else:
		return FileAccess.file_exists(file_path)

func load_gltf_at_runtime(file_path : String) -> Node3D:
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	if gltf_doc.append_from_file(file_path, gltf_state) == OK:
		var gltf_scene : Node3D = gltf_doc.generate_scene(gltf_state)
		return gltf_scene
	return null

func pack_model(file_path : String) -> PackedScene:
	var model := load_gltf_at_runtime(file_path)
	
	if model == null:
		printerr("Unable to pack model %s" % file_path)
		return null
	
	var resource := PackedScene.new()
	resource.pack(model)
	return resource

func on_player_died() -> void:
	get_tree().paused = true

	lose_menu = LOSE_MENU.instantiate()
	add_child(lose_menu)

	var menu_choice: LoseMenu.MenuChoice = await lose_menu.s_choice_made

	# Free player/any other persistent nodes
	SceneLoader.clear_persistent_nodes()

	lose_menu.queue_free()
	lose_menu = null

	if menu_choice == LoseMenu.MenuChoice.PLAY_AGAIN:
		stored_try_again_char_name = player.character.character_name
		if stored_try_again_char_name == "RandomGags":
			# sory
			stored_try_again_char_name = "RandomToon"

	# Return to title screen
	SceneLoader.load_into_scene("res://scenes/title_screen/title_screen.tscn")

	s_player_died.emit()

func stop_player_safe() -> void:
	if is_instance_valid(get_player()):
		get_player().state = Player.PlayerState.STOPPED
		get_player().set_animation('neutral')

func free_all_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func resume_player_safe() -> void:
	if is_instance_valid(get_player()):
		get_player().state = Player.PlayerState.WALK

func barrier(_signal: Signal, timeout: float = 10.0) -> Signal:
	return SignalBarrier.new([_signal, Task.delay(timeout)], SignalBarrier.BarrierType.ANY).s_complete

func do_item_hover(item: Item) -> void:
	var desc: String = item.big_description if Util.get_player().see_descriptions else item.item_description
	HoverManager.hover(desc, 18, 0.025, item.item_name, item.shop_category_color.darkened(0.3))

#region Camera Functions
func shake_camera(cam : Camera3D, time : float, offset : float, taper := true, x := true, y := true, z := true) -> void:
	var base_pos := cam.global_position
	stop_camera_shake = false
	
	var timer := cam.get_tree().create_timer(time)
	while timer.time_left > 0 and not stop_camera_shake:
		await s_process_frame
		var new_offset : float
		if taper:
			new_offset = offset * timer.time_left/time
		else:
			new_offset = offset
		if x:
			cam.global_position.x = base_pos.x + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if y:
			cam.global_position.y = base_pos.y + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if z:
			cam.global_position.z = base_pos.z + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
#endregion

#region Mod Cogs

func get_mod_cog_health_mod() -> float:
	return 1.2 + (floor_number * 0.15)

#endregion

#region Boss Drops

func make_boss_chests(holder_node: Node3D, pos_node: Node3D) -> void:
	# For a boss battle, we give the following rewards:
	# 1. A Super candy (super damage, super defense, super luck, super evasiveness)
	# 2. A track frame
	# 3. A toon-up consumable (not high dive) if they don't have one of a type. If they do, give a progressive instead
	# 4. A jellybean consumable, if they have less than 20 beans. If they have 20 or more, give a progressive instead
	if not player:
		await s_player_assigned
	var x_points: Array = [-3.75, -1.25, 1.25, 3.75]
	var chest_scene: PackedScene = load('res://objects/interactables/treasure_chest/treasure_chest.tscn')
	var light_beam: Gradient = load("res://models/props/treasure_chest/sunrays/bosschest_sunrays.tres")
	for i in range(4):
		var chest: TreasureChest = chest_scene.instantiate()
		chest.item_pool = ItemService.PROGRESSIVE_POOL
		holder_node.add_child(chest)
		chest.global_position = pos_node.to_global(Vector3(x_points[i], 0, 0))
		chest.global_rotation = pos_node.global_rotation
		chest.override_replacement_rolls = true
		match i:
			0:
				# Give a random super candy
				chest.item_pool = load("res://objects/items/pools/super_candies.tres")
			1:
				# Give a random track frame
				chest.override_item = load("res://objects/items/resources/passive/track_frame.tres")
			2:
				# Give a toon-up consumable of a type that they don't have any of, except high dive
				# If they have one of each non-high dive one, it gives a progressive instead
				if player.stats.toonups[ToonUp.MovieType.LIPSTICK] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/lipstick.tres")
				elif player.stats.toonups[ToonUp.MovieType.PIXIE] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/pixie.tres")
				elif player.stats.toonups[ToonUp.MovieType.FEATHER] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/feather.tres")
				elif player.stats.toonups[ToonUp.MovieType.CANE] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/bamboo_cane.tres")
				elif player.stats.toonups[ToonUp.MovieType.JUGGLING] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/juggling.tres")
				elif player.stats.toonups[ToonUp.MovieType.MEGAPHONE] == 0:
					chest.override_item = load("res://objects/items/resources/passive/toonups/megaphone.tres")
			3:
				# Chance to give Player some money, guaranteed if they're < 20
				if player.stats.money < 20 or RandomService.randi_channel('true_random') % 2 == 0:
					chest.item_pool = load("res://objects/items/pools/jellybeans.tres")
		chest.update_texture(chest.BOSS_TEXTURE)
		chest.set_ray_gradient(light_beam)

#endregion
