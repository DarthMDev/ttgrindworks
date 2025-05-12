@tool
extends LawbotPuzzleGrid
class_name PuzzleAvoidSkulls

## Config
@export var flip_time := 1.0
@export var skull_chance := 4

## Locals
var timer : Timer


func initialize_game() -> void:
	randomize_panels()
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = flip_time
	timer.one_shot = false
	timer.timeout.connect(randomize_panels)
	timer.start()

func randomize_panels() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			match panel.panel_shape:
				PuzzlePanel.PanelShape.NOTHING:
					if RandomService.randi_channel('puzzles') % skull_chance == 0:
						panel.panel_shape = PuzzlePanel.PanelShape.DOT
				PuzzlePanel.PanelShape.DOT:
					panel.panel_shape = PuzzlePanel.PanelShape.SKULL
				PuzzlePanel.PanelShape.SKULL:
					panel.panel_shape = PuzzlePanel.PanelShape.NOTHING
	
	# Check if player is standing on a skull
	for panel : PuzzlePanel in player_cells:
		if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
			lose_game()

func player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()

func panel_shape_changed(panel : PuzzlePanel, _shape : PuzzlePanel.PanelShape) -> void:
	panel.set_color(Color.RED)

func get_game_text() -> String:
	return "Avoid the Skulls"
