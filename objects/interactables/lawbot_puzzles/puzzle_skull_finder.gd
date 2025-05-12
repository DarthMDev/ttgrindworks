@tool
extends LawbotPuzzleGrid
class_name PuzzleSkullFinder

var bombs : Array[Vector2i] = []
## Number of bombs game attempts to place
@export var bomb_count := 6
@export var one_bomb_per_column := false
var panels := {}

## Document each panel place and place bombs
func initialize_game() -> void:
	var _bomb_count := bomb_count
	while bomb_count > 0:
		var pos_check := Vector2i(RandomService.randi_channel('puzzles')%grid_width,(RandomService.randi_channel('puzzles')%(grid_height-1))+1)
		if pos_check not in bombs:
			bombs.append(Vector2i(pos_check.x,pos_check.y))
		bomb_count-=1
	if one_bomb_per_column:
		verify_one_per_column()
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
			panels[panel] = Vector2i(i,j)
	bomb_count = _bomb_count

func panel_shape_changed(panel : PuzzlePanel, _shape : PuzzlePanel.PanelShape) -> void:
	panel.set_color(Color.RED)

func get_panel(x : int, y: int) -> PuzzlePanel:
	for panel in panels.keys():
		if panels[panel] == Vector2i(x,y):
			return panel
	return null

func get_surrounding_bombs(x : int,y : int) -> int:
	# Get surrounding panels
	var positions := get_adjacent_positions(x,y)
	
	# Find number of bombs surrounding 
	var nearby_bombs := 0
	for panel in positions:
		if panel in bombs:
			nearby_bombs+=1
	
	return nearby_bombs

func check_chain(positions : Array[Vector2i]) -> void:
	for pos in positions:
		var panel := get_panel(pos.x,pos.y)
		if panel:
			if panel.panel_shape == PuzzlePanel.PanelShape.SQUARE:
				check_panel(panel, false)

func player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SQUARE:
		check_panel(panel)

func check_panel(panel : PuzzlePanel, player_stepped := true) -> void:
	var pos : Vector2i = panels.get(panel)
	if pos in bombs:
		panel.panel_shape = PuzzlePanel.PanelShape.SKULL
		if player_stepped:
			lose_game()
		if player_stepped:
			check_chain(get_adjacent_positions(pos.x, pos.y))
		return
	match get_surrounding_bombs(pos.x,pos.y):
		0: panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
		1: panel.panel_shape = PuzzlePanel.PanelShape.ONE
		2: panel.panel_shape = PuzzlePanel.PanelShape.TWO
		3: panel.panel_shape = PuzzlePanel.PanelShape.THREE
		4: panel.panel_shape = PuzzlePanel.PanelShape.FOUR
		5: panel.panel_shape = PuzzlePanel.PanelShape.FIVE
		_: panel.panel_shape = PuzzlePanel.PanelShape.SIX
	
	if panel.panel_shape == PuzzlePanel.PanelShape.NOTHING:
		check_chain(get_adjacent_positions(pos.x,pos.y))

func get_adjacent_positions(x: int,y: int) -> Array[Vector2i]:
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

func bomb_in_column(column : int) -> bool:
	for i in grid_width:
		if Vector2i(column, i) in bombs:
			return true
	return false

func verify_one_per_column() -> void:
	for i in grid_height:
		if not bomb_in_column(i):
			bombs.append(Vector2i(i, RandomService.randi_channel('puzzles') % (grid_height-1)+1))

func get_game_text() -> String:
	return "Skull Finder!"
