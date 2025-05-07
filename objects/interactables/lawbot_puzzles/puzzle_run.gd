@tool
extends LawbotPuzzleGrid
class_name PuzzleRun

# Config
@export var wait_time := 0.25

# Locals
var row_num := -1
var move_timer : Timer


func initialize_game() -> void:
	row_num = 0
	
	# Set all panels to no shape
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
	
	# Create the move timer
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.wait_time = wait_time
	move_timer.one_shot = false
	move_timer.timeout.connect(move_skulls)
	move_timer.start()

func panel_shape_changed(panel : PuzzlePanel, shape : PuzzlePanel.PanelShape) -> void:
	panel.set_color(Color.RED)
	
	if panel in player_cells and shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()

func move_skulls() -> void:
	# Clear previous row
	for i in grid_width:
		grid[i][row_num].panel_shape = PuzzlePanel.PanelShape.NOTHING
	
	# Move the row number
	row_num += 1
	if row_num > grid_height - 1:
		row_num = 0
	
	# Place skulls on new row
	for i in grid_width:
		grid[i][row_num].panel_shape = PuzzlePanel.PanelShape.SKULL

func player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()

func get_game_text() -> String:
	return "Run!"
