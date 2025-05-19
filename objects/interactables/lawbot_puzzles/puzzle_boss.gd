@tool
extends LawbotPuzzleGrid
class_name PuzzleBoss

const DEBUG_QUICK_RUN := false
const DEBUG_ALL_PUZZLES := false

enum BossPhase {
	INACTIVE,
	INTRO,
	DRAGTHREE,
	MATCHING,
	AVOID,
	RUNTRANSITION,
	SKULLFINDER,
	PHASETRANSITION,
	CLEANUP,
}
@warning_ignore("int_as_enum_without_match")
var phase : BossPhase = -1 as BossPhase:
	set(x):
		phase_ended(phase)
		phase = x
		phase_changed(phase)

var phase_order : Array[BossPhase] = []

#region BOSS FUNCTIONALITY
func initialize_game() -> void:
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	phase = BossPhase.INACTIVE
	s_began_interaction.connect(on_interaction_begin)
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.area.set_collision_mask_value(4, true)
	if DEBUG_QUICK_RUN:
		phase_order.append(BossPhase.SKULLFINDER)
		return
	phase_order = [BossPhase.AVOID, BossPhase.DRAGTHREE, BossPhase.MATCHING]
	RandomService.array_shuffle_channel('true_random', phase_order)
	if not DEBUG_ALL_PUZZLES:
		phase_order.pop_back()
	phase_order.append(BossPhase.SKULLFINDER)

func get_random_panel() -> PuzzlePanel:
	return grid[RandomService.randi_channel('true_random') % grid_width - 1][RandomService.randi_channel('true_random') % grid_height - 1]

func set_all_panel_shapes(shape : PuzzlePanel.PanelShape) -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel = grid[i][j]
			panel.panel_shape = shape

func set_all_panel_colors(color : Color) -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.set_color(color)

func on_interaction_begin() -> void:
	pass

func get_panel_center(panel : PuzzlePanel) -> Vector3:
	return panel.to_global(Vector3(0.5, 0.0, 0.5))

func move_to_next_phase() -> void:
	if not phase_order.is_empty():
		phase = phase_order.pop_back()
		if not phase == BossPhase.SKULLFINDER:
			show_game_title()

func get_game_text() -> String:
	match phase:
		BossPhase.SKULLFINDER:
			return "Skull Finder"
		BossPhase.AVOID:
			return "Get to the Safe Zone"
		BossPhase.DRAGTHREE:
			return "Drag Three & Avoid"
		BossPhase.MATCHING:
			return "Matching"
	return ""

#endregion

#region PHASE CHANGED FUNCTIONS

func player_stepped_on(panel : PuzzlePanel) -> void:
	match phase:
		BossPhase.INACTIVE:
			inactive_player_stepped_on(panel)
		BossPhase.DRAGTHREE:
			drag_player_stepped_on(panel)
		BossPhase.MATCHING:
			match_player_stepped_on(panel)
		BossPhase.SKULLFINDER:
			finder_player_stepped_on(panel)

func swap_collision_layer() -> void:
	for panel: PuzzlePanel in get_all_panels():
		panel.area.set_collision_mask_value(Globals.PLAYER_COLLISION_LAYER, false)
		panel.area.set_collision_mask_value(Globals.HAZARD_COLLISION_LAYER, true)

func player_stepped_off(_panel : PuzzlePanel) -> void:
	pass

func panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match phase:
		BossPhase.INACTIVE:
			inactive_shape_changed(panel, shape)
		BossPhase.DRAGTHREE:
			drag_panel_shape_changed(panel, shape)
		BossPhase.MATCHING:
			match_panel_shape_changed(panel, shape)
		BossPhase.AVOID:
			avoid_panel_shape_changed(panel, shape)
		BossPhase.SKULLFINDER:
			finder_panel_shape_changed(panel, shape)

func phase_changed(new_phase : BossPhase) -> void:
	match new_phase:
		BossPhase.INACTIVE:
			inactive_initialize()
		BossPhase.INTRO:
			play_intro()
		BossPhase.DRAGTHREE:
			drag_initialize()
		BossPhase.MATCHING:
			match_initialize()
		BossPhase.AVOID:
			avoid_initialize()
		BossPhase.SKULLFINDER:
			finder_initialize()

func phase_ended(old_phase : BossPhase) -> void:
	match old_phase:
		BossPhase.INACTIVE:
			inactive_end()
		BossPhase.DRAGTHREE:
			drag_end()
		BossPhase.MATCHING:
			match_end()
		BossPhase.AVOID:
			avoid_end()
		BossPhase.SKULLFINDER:
			finder_end()

func win_game() -> void:
	if not phase_order.is_empty():
		phase = BossPhase.PHASETRANSITION
		await do_phase_transition()
		move_to_next_phase()
	else:
		phase = BossPhase.CLEANUP
		await room_root.do_end_cutscene().finished
		super()

func _process(delta : float) -> void:
	match phase:
		BossPhase.DRAGTHREE:
			_drag_process(delta)

#endregion

#region IDLE STATE
const INACTIVE_BREATHE_TIME := 0.3
const INACTIVE_PANEL_BREATHE_TIME := 1.0
var inactive_random_timer : Timer 
var inactive_row := 0
var inactive_tweens : Array[Tween] = []

func inactive_initialize() -> void:
	inactive_row = grid_height - 1
	inactive_random_timer = Timer.new()
	add_child(inactive_random_timer)
	inactive_random_timer.wait_time = INACTIVE_BREATHE_TIME
	inactive_random_timer.timeout.connect(inactive_timer_timeout)
	inactive_random_timer.start()
	set_all_panel_shapes(PuzzlePanel.PanelShape.SQUARE)

func inactive_timer_timeout() -> void:
	inactive_move_row()

func inactive_shape_changed(panel : PuzzlePanel, _shape : PuzzlePanel.PanelShape) -> void:
	panel.set_color(Color("ff000000"))

func inactive_panel_do_breath(panel : PuzzlePanel) -> void:
	if panel in player_cells:
		phase = BossPhase.INTRO
	var breath_tween := create_tween()
	breath_tween.tween_method(panel.set_color, Color(1.0, 0.0, 0.0, 1.0), Color(1.0, 0.0, 0.0, 1.0), INACTIVE_PANEL_BREATHE_TIME)
	breath_tween.tween_method(panel.set_color, Color(1.0, 0.0, 0.0, 1.0), Color(1.0, 0.0, 0.0, 0.0), INACTIVE_PANEL_BREATHE_TIME)
	inactive_tweens.append(breath_tween)
	breath_tween.finished.connect(
		func():
			breath_tween.kill()
			inactive_tweens.erase(breath_tween)
	)

func inactive_move_row() -> void:
	# Move the row number
	inactive_row -= 1
	if inactive_row < 0:
		inactive_row = grid_height - 1
	
	# Place skulls on new row
	for i in grid_width:
		inactive_panel_do_breath(grid[i][inactive_row])

func inactive_end() -> void:
	for tween in inactive_tweens:
		tween.kill()
	inactive_tweens.clear()
	set_all_panel_colors(Color.WHITE)
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	inactive_random_timer.queue_free()

func inactive_player_stepped_on(_panel : PuzzlePanel) -> void:
	pass

#endregion

#region INTRO STATE

@onready var room_root := $"../.."

func play_intro() -> void:
	await room_root.play_intro().finished
	move_to_next_phase()

#endregion

#region DRAG THREE
var drag_panels := {}
var drag_remaining_shapes : Array[PuzzlePanel.PanelShape] = [
	PuzzlePanel.PanelShape.DIAMOND,
	PuzzlePanel.PanelShape.X,
	PuzzlePanel.PanelShape.TRIANGLE
]
var drag_player_panel : PuzzlePanel
var drag_skull_chance := 14
var drag_shape_placements := [1, 4, 7]

func drag_initialize() -> void:
	if not Util.on_easy_floor(): drag_skull_chance = 12
	
	# Randomize Initial Shape Placements
	RandomService.array_shuffle_channel('true_random', drag_shape_placements)
	var shape_spaces := {}
	for shape in drag_remaining_shapes:
		grid[3 * drag_remaining_shapes.find(shape)][0].panel_shape = shape
		grid[3 * drag_remaining_shapes.find(shape) + 2][0].panel_shape = shape
		grid[drag_shape_placements.pop_back()][grid_height - 2].panel_shape = shape
	
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			drag_panels[panel] = Vector2i(i,j)
			
			# Get shapes when spots are reached
			if Vector2i(i,j) in shape_spaces:
				panel.panel_shape = shape_spaces[Vector2i(i,j)]
			
			# All top panels are skulls
			if j == grid[i].size()-1:
				panel.panel_shape = PuzzlePanel.PanelShape.SKULL
	
	drag_randomize_panels()
	drag_timer = Timer.new()
	add_child(drag_timer)
	drag_timer.wait_time = drag_flip_time
	drag_timer.one_shot = false
	drag_timer.timeout.connect(drag_randomize_panels)
	drag_timer.start()

	drag_player_panel = player_cells[0]

## Config
var drag_flip_time := 1.0

## Locals
var drag_timer : Timer

func drag_randomize_panels() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			if j == 0:
				continue
			match panel.panel_shape:
				PuzzlePanel.PanelShape.NOTHING:
					if RandomService.randi_channel('puzzles') % drag_skull_chance == 0:
						panel.panel_shape = PuzzlePanel.PanelShape.DOT
				PuzzlePanel.PanelShape.DOT:
					panel.panel_shape = PuzzlePanel.PanelShape.SKULL
				PuzzlePanel.PanelShape.SKULL:
					panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
	
	# Check if player is standing on a skull
	for panel : PuzzlePanel in player_cells:
		if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
			pass
			lose_game()

func drag_panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.TRIANGLE:
			panel.set_color(Color.GREEN)
		PuzzlePanel.PanelShape.DIAMOND:
			panel.set_color(BLUE)
		PuzzlePanel.PanelShape.X:
			panel.set_color(Color.YELLOW)
		_:
			panel.set_color(Color.RED)

func drag_player_stepped_on(panel : PuzzlePanel) -> void:
	if not drag_player_panel:
		drag_player_panel = panel
		return
	if get_panel_coords(panel).y == 0 and not drag_get_bottom_row_swappable(panel.panel_shape):
		return
	if panel.panel_shape == PuzzlePanel.PanelShape.NOTHING or panel.panel_shape == PuzzlePanel.PanelShape.DOT:
		if drag_player_panel.panel_shape in drag_remaining_shapes:
			drag_swap_panels(drag_player_panel, panel)
			drag_check_panel(panel)
	elif panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()
	drag_player_panel = panel

func drag_get_bottom_row_swappable(panel_shape : PuzzlePanel.PanelShape) -> bool:
	var valid_swaps : Array[PuzzlePanel.PanelShape] = [
		PuzzlePanel.PanelShape.NOTHING,
		PuzzlePanel.PanelShape.DOT,
		PuzzlePanel.PanelShape.SKULL
	]
	return panel_shape in valid_swaps

func drag_swap_panels(panel1 : PuzzlePanel, panel2: PuzzlePanel) -> void:
	var shape2 := panel2.panel_shape
	panel2.panel_shape = panel1.panel_shape
	panel1.panel_shape = shape2

func drag_drop_shape() -> void:
	drag_player_panel = null

func drag_get_panel(x : int, y: int) -> PuzzlePanel:
	for panel in drag_panels.keys():
		if drag_panels[panel] == Vector2i(x,y):
			return panel
	return null

func drag_check_panel(panel : PuzzlePanel) -> void:
	var pos : Vector2i = drag_panels.get(panel)
	var shape := panel.panel_shape
	
	var checks := []
	checks.append_array([
		[drag_get_panel(pos.x-1,pos.y),drag_get_panel(pos.x+1,pos.y)],
		[drag_get_panel(pos.x,pos.y-1),drag_get_panel(pos.x,pos.y+1)],
		[drag_get_panel(pos.x,pos.y-1),drag_get_panel(pos.x,pos.y-2)],
		[drag_get_panel(pos.x,pos.y+1),drag_get_panel(pos.x,pos.y+2)],
		[drag_get_panel(pos.x-1,pos.y),drag_get_panel(pos.x-2,pos.y)],
		[drag_get_panel(pos.x+1,pos.y),drag_get_panel(pos.x+2,pos.y)],
	])
	for i in checks.size():
		if not checks[i][0] or not checks[i][1]:
			continue
		if checks[i][0].panel_shape == shape and checks[i][1].panel_shape == shape:
			drag_remove_shape(shape)
			drag_skull_chance /= 2
			return

func drag_remove_shape(shape : PuzzlePanel.PanelShape) -> void:
	drag_remaining_shapes.erase(shape)
	for i in grid.size():
		for j in grid[i].size():
			if grid[i][j].panel_shape == shape:
				grid[i][j].panel_shape = PuzzlePanel.PanelShape.NOTHING
	if drag_remaining_shapes.is_empty():
		win_game()

func _drag_process(_delta : float) -> void:
	pass
	#if player_cells.is_empty():
		#drag_player_panel = null

func drag_end() -> void:
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	drag_timer.queue_free()

#endregion

#region MATCHING

var match_squares := 0
var match_triangles := 0
var match_cogs : Array[Cog] = []
var match_time := 45.0
var match_cog2_spawn_time : float:
	get:
		if Util.on_easy_floor():
			return 20.0
		return 10.0
var match_cog_tweens : Array[Tween] = []
const COG_PATH := "res://objects/interactables/lawbot_puzzles/puzzle_boss_objects/puzzle_cog.tscn"
const SPARK_SFX := "res://audio/sfx/battle/cogs/misc/LB_sparks_1.ogg"
const MATCH_UI := "res://objects/interactables/lawbot_puzzles/puzzle_boss_objects/matching_boss_ui.tscn"

var match_initialized := false
var match_ui : Control

signal s_match_shape_count_changed(triangles : int)


## Overwrite this function to initialize your game
func match_initialize() -> void:
	match_randomize_panels()
	
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.area.body_entered.connect(match_body_entered.bind(panel))
	Util.run_timer(match_time).s_timeout.connect(match_timeout)
	match_spawn_cogs()
	match_initialized = true
	match_initialize_ui()

func match_initialize_ui() -> void:
	match_ui = GameLoader.load(MATCH_UI).instantiate()
	add_child(match_ui)
	match_ui.setup(match_triangles + match_squares, match_triangles)
	s_match_shape_count_changed.connect(match_ui.set_value)

func match_body_entered(body : Node3D, panel : PuzzlePanel) -> void:
	if body is Cog:
		match_cog_entered_panel(panel)

func match_cog_entered_panel(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.TRIANGLE:
		panel.panel_shape = PuzzlePanel.PanelShape.SQUARE

func match_spawn_cogs() -> void:
	match_spawn_cog()
	var timer := Timer.new()
	timer.wait_time = match_cog2_spawn_time
	add_child(timer)
	timer.start()
	timer.timeout.connect(
		func():
			timer.queue_free()
			match_spawn_cog()
	)

func match_spawn_cog() -> void:
	var cog : Cog = load(COG_PATH).instantiate()
	match_cogs.append(cog)
	add_child(cog)
	cog.global_position = get_panel_center(get_random_panel())
	cog.set_animation('drop')
	cog.department_emblem.hide()
	cog.body.nametag_node.hide()
	cog.animator_seek(3.0)
	cog.get_node('PlayerDetection').body_entered.connect(match_cog_body_entered)
	cog.animator.animation_finished.connect(match_cog_spawned.bind(cog))
	AudioManager.play_sound(load(SPARK_SFX))

func match_cog_body_entered(body : Node3D) -> void:
	if body is Player:
		lose_game()

func match_move_cog(cog : Cog) -> void:
	var panel : PuzzlePanel
	while not panel or panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		panel = get_random_panel()
	var cog_tween := cog.move_to(get_panel_center(panel), cog.walk_speed)
	match_cog_tweens.append(cog_tween)
	cog_tween.finished.connect(
		func():
			match_cog_tweens.erase(cog_tween)
			cog_tween.kill()
			match_move_cog(cog)
	)

func match_cog_spawned(_anim, cog : Cog) -> void:
	match_move_cog(cog)
	cog.get_node('PlayerDetection').set_deferred('monitoring', true)

func match_player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()
		return
	if panel.panel_shape == PuzzlePanel.PanelShape.SQUARE:
		panel.panel_shape = PuzzlePanel.PanelShape.TRIANGLE

## Overwrite this function to change the colors of shapes
func match_panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.SKULL: panel.set_color(Color.RED)
	
	match shape:
		PuzzlePanel.PanelShape.TRIANGLE:
			panel.set_color(Color.GREEN)
			match_triangles += 1
			if match_initialized:
				match_squares -= 1
		PuzzlePanel.PanelShape.SQUARE:
			panel.set_color(Color.RED)
			if match_initialized:
				match_triangles -= 1
			match_squares += 1
	
	s_match_shape_count_changed.emit(match_triangles)

func match_randomize_panels() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			if RandomService.randi_channel('true_random') % 2== 0:
				panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
			else:
				panel.panel_shape = PuzzlePanel.PanelShape.TRIANGLE

func match_timeout() -> void:
	print("Game Totals: %d triangles, and %d squares." % [match_triangles, match_squares])
	if match_triangles > match_squares:
		win_game()
	else:
		lose_game()
		win_game()

func match_end() -> void:
	for tween in match_cog_tweens:
		tween.kill()
	for cog in match_cogs:
		cog.get_node('PlayerDetection').queue_free()
		cog.lose()
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	if is_instance_valid(match_ui):
		match_ui.queue_free()

#endregion

#region AVOID

var avoid_timer : Timer
var avoid_safe_panels : Array[PuzzlePanel] = []
var avoid_rounds := 6
var avoid_wait_time := 5.0

func avoid_initialize() -> void:
	if not Util.on_easy_floor():
		avoid_wait_time = 4.0
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	avoid_timer = Timer.new()
	avoid_timer.set_one_shot(true)
	add_child(avoid_timer)
	avoid_start()

func avoid_start() -> void:
	for panel: PuzzlePanel in get_all_panels():
		panel.collision_box.size = Vector3(0.8, 100.0, 0.8)
	
	var size := 3
	while avoid_rounds > 0:
		if not avoid_safe_panels.is_empty():
			var prev_point := get_panel_coords(avoid_safe_panels[0])
			while prev_point.distance_to(get_panel_coords(avoid_safe_panels[0])) < 5:
				avoid_safe_panels = avoid_get_random_region(size)
		else:
			avoid_safe_panels = avoid_get_random_region(size)
		for panel : PuzzlePanel in get_all_panels():
			if panel in avoid_safe_panels:
				panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
			else:
				panel.panel_shape = PuzzlePanel.PanelShape.DOT
				panel.fade(1.0, 2.0)
		avoid_timer.wait_time = avoid_wait_time - 1.0
		if size > 1 and avoid_rounds % 2 == 1:
			size -= 1
		avoid_timer.start()
		await avoid_timer.timeout
		
		# Warning
		for panel : PuzzlePanel in get_all_panels():
			if panel.panel_shape == PuzzlePanel.PanelShape.DOT:
				panel.custom_fade(1.0, 0.5).finished.connect(panel.custom_fade.bind(0.5, 0.5))
		avoid_timer.wait_time = 1.0
		avoid_timer.start()
		await avoid_timer.timeout
		
		for panel : PuzzlePanel in get_all_panels():
			if panel.panel_shape == PuzzlePanel.PanelShape.DOT:
				panel.panel_shape = PuzzlePanel.PanelShape.SKULL
				if panel in player_cells:
					lose_game()
					avoid_timer.wait_time = 4.0
				else:
					avoid_timer.wait_time = 2.0
		avoid_timer.start()
		await avoid_timer.timeout
		
		if avoid_rounds % 2 == 1:
			avoid_wait_time = max(1.75, avoid_wait_time * 0.8)
		avoid_rounds -= 1
	win_game()

func avoid_get_random_region(size := 3) -> Array[PuzzlePanel]:
	var panel_array : Array[PuzzlePanel] = []
	var panel : PuzzlePanel = get_random_panel()
	var coords : Vector2i = get_panel_coords(panel)
	
	# Move panel out of illegal area
	while coords.x > grid_width - 2: coords.x -= 1
	while coords.x < 2: coords.x += 1
	while coords.y > grid_height - 3: coords.y -= 1
	while coords.y < 3: coords.y += 1
	
	# Get our new panel
	panel = get_panel(coords.x, coords.y)
	
	# Get our safe zone
	panel_array.append(panel)
	if size == 3:
		panel_array.append_array(get_adjacent_panels(coords.x, coords.y))
	elif size == 2:
		panel_array.append(get_panel(coords.x - 1, coords.y - 1))
		panel_array.append(get_panel(coords.x - 1, coords.y))
		panel_array.append(get_panel(coords.x, coords.y - 1))
	
	return panel_array

func avoid_panel_shape_changed(panel : PuzzlePanel, shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.SQUARE:
			panel.set_color(Color.GREEN)
		_:
			panel.set_color(Color.RED)

func avoid_player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()

func avoid_end() -> void:
	avoid_timer.queue_free()
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	for panel: PuzzlePanel in get_all_panels():
		panel.collision_box.size = Vector3(0.72, 100.0, 0.72)

#endregion

#region SKULL FINDER

var finder_bombs : Array[Vector2i] = []
## Number of bombs game attempts to place
var finder_bomb_count := 28
var finder_panels := {}
var finder_current_row := 0
signal s_finder_row_reached(row_num: int)

## Document each panel place and place bombs
func finder_initialize() -> void:
	if Util.on_easy_floor():
		finder_bomb_count = 24
	
	while finder_bomb_count > 0:
		var pos_check := Vector2i(RandomService.randi_channel('puzzles')%grid_width,(RandomService.randi_channel('puzzles')%(grid_height-2))+1)
		if pos_check not in finder_bombs:
			finder_bombs.append(Vector2i(pos_check.x,pos_check.y))
		finder_bomb_count-=1
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			if j == grid_height - 1:
				panel.panel_shape = PuzzlePanel.PanelShape.TRIANGLE
			else:
				panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
			finder_panels[panel] = Vector2i(i,j)
	for panel in player_cells:
		finder_player_stepped_on(panel)

func finder_panel_shape_changed(panel : PuzzlePanel, shape : PuzzlePanel.PanelShape) -> void:
	if shape == PuzzlePanel.PanelShape.TRIANGLE:
		panel.set_color(Color.GREEN)
	else:
		panel.set_color(Color.RED)

func finder_get_panel(x : int, y: int) -> PuzzlePanel:
	for panel in finder_panels.keys():
		if finder_panels[panel] == Vector2i(x,y):
			return panel
	return null

func finder_get_surrounding_bombs(x : int,y : int) -> int:
	# Get surrounding panels
	var positions := finder_get_adjacent_positions(x,y)
	
	# Find number of bombs surrounding 
	var nearby_bombs := 0
	for panel in positions:
		if panel in finder_bombs:
			nearby_bombs+=1
	
	return nearby_bombs

func finder_check_chain(positions : Array[Vector2i]) -> void:
	for pos in positions:
		var panel := finder_get_panel(pos.x,pos.y)
		if panel:
			if panel.panel_shape == PuzzlePanel.PanelShape.SQUARE:
				finder_check_panel(panel, false)

func finder_player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SQUARE:
		finder_check_panel(panel)
	if get_panel_coords(panel).y == grid_height - 1:
		win_game()
	
	if get_panel_coords(panel).y > finder_current_row:
		finder_current_row = get_panel_coords(panel).y
		s_finder_row_reached.emit(finder_current_row)

func finder_check_panel(panel : PuzzlePanel, player_stepped := true) -> void:
	var pos : Vector2i = finder_panels.get(panel)
	if pos in finder_bombs:
		panel.panel_shape = PuzzlePanel.PanelShape.SKULL
		if player_stepped:
			lose_game()
		if player_stepped:
			finder_check_chain(finder_get_adjacent_positions(pos.x, pos.y))
		return
	match finder_get_surrounding_bombs(pos.x,pos.y):
		0: panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
		1: panel.panel_shape = PuzzlePanel.PanelShape.ONE
		2: panel.panel_shape = PuzzlePanel.PanelShape.TWO
		3: panel.panel_shape = PuzzlePanel.PanelShape.THREE
		4: panel.panel_shape = PuzzlePanel.PanelShape.FOUR
		5: panel.panel_shape = PuzzlePanel.PanelShape.FIVE
		_: panel.panel_shape = PuzzlePanel.PanelShape.SIX
	
	if panel.panel_shape == PuzzlePanel.PanelShape.NOTHING:
		finder_check_chain(finder_get_adjacent_positions(pos.x,pos.y))

func finder_get_adjacent_positions(x: int,y: int) -> Array[Vector2i]:
	var positions : Array[Vector2i] = [
		Vector2i(x-1,y-1),
		Vector2i(x,y-1),
		Vector2i(x+1,y-1),
		Vector2i(x+1,y),
		Vector2i(x+1,y+1),
		Vector2i(x,y+1),
		Vector2i(x-1,y+1),
		Vector2i(x-1,y)
	]
	return positions

func finder_end() -> void:
	set_all_panel_shapes(PuzzlePanel.PanelShape.NOTHING)
	swap_collision_layer()

#endregion

#region TRANSITION STATE

func do_phase_transition() -> void:
	await room_root.do_transition_cutscene().finished

#endregion

#region END CUTSCENE

#endregion
