extends LawbotPuzzleGrid
class_name PuzzleDragThree

var panels := {}
var remaining_shapes : Array[PuzzlePanel.PanelShape] = [
	PuzzlePanel.PanelShape.DIAMOND,
	PuzzlePanel.PanelShape.X,
	PuzzlePanel.PanelShape.TRIANGLE
]
var player_panel : PuzzlePanel

func initialize_game() -> void:
	# Randomize Initial Shape Placements
	var shape_spaces := {}
	for shape in remaining_shapes:
		for i in 4:
			var space : Vector2i
			while not space or space in shape_spaces.keys():
				space = Vector2i(RandomService.randi_channel('puzzles')%grid_width,RandomService.randi_range_channel('puzzles',0,grid_height-2))
			shape_spaces[space] = shape
	
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panels[panel] = Vector2i(i,j)
			
			# Get shapes when spots are reached
			if Vector2i(i,j) in shape_spaces:
				panel.panel_shape = shape_spaces[Vector2i(i,j)]
			
			# All top panels are skulls
			if j == grid[i].size()-1:
				panel.panel_shape = PuzzlePanel.PanelShape.SKULL

func panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.TRIANGLE:
			panel.set_color(Color.GREEN)
		PuzzlePanel.PanelShape.DIAMOND:
			panel.set_color(Color("4d4dff"))
		_:
			panel.set_color(Color.RED)

func player_stepped_on(panel : PuzzlePanel) -> void:
	if not player_panel and not panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		player_panel = panel
		return
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()
		player_panel = panel
		return
	elif not player_panel.panel_shape == PuzzlePanel.PanelShape.NOTHING:
		if panel.panel_shape == PuzzlePanel.PanelShape.NOTHING:
			panel.panel_shape = player_panel.panel_shape
			player_panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
			check_panel(panel)
	
	player_panel = panel

func get_panel(x : int, y: int) -> PuzzlePanel:
	for panel in panels.keys():
		if panels[panel] == Vector2i(x,y):
			return panel
	return null

func check_panel(panel : PuzzlePanel) -> void:
	var pos : Vector2i = panels.get(panel)
	var shape := panel.panel_shape
	
	var checks := []
	checks.append_array([
		[get_panel(pos.x-1,pos.y),get_panel(pos.x+1,pos.y)],
		[get_panel(pos.x,pos.y-1),get_panel(pos.x,pos.y+1)],
		[get_panel(pos.x,pos.y-1),get_panel(pos.x,pos.y-2)],
		[get_panel(pos.x,pos.y+1),get_panel(pos.x,pos.y+2)],
		[get_panel(pos.x-1,pos.y),get_panel(pos.x-2,pos.y)],
		[get_panel(pos.x+1,pos.y),get_panel(pos.x+2,pos.y)],
	])
	for i in checks.size():
		if not checks[i][0] or not checks[i][1]:
			continue
		if checks[i][0].panel_shape == shape and checks[i][1].panel_shape == shape:
			remove_shape(shape)
			return

func remove_shape(shape : PuzzlePanel.PanelShape) -> void:
	remaining_shapes.erase(shape)
	for i in grid.size():
		for j in grid[i].size():
			if grid[i][j].panel_shape == shape:
				grid[i][j].panel_shape = PuzzlePanel.PanelShape.NOTHING
	if remaining_shapes.is_empty():
		win_game()

func _process(_delta) -> void:
	if player_cells.is_empty():
		player_panel = null

func get_game_text() -> String:
	return "Drag three of a color in a row"
