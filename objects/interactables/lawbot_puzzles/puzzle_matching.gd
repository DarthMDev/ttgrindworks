@tool
extends LawbotPuzzleGrid
class_name PuzzleMatching


## Locals
var squares := 0
var triangles := 0


func initialize_game() -> void:
	randomize_panels()

func randomize_panels() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			if j == grid[i].size()-1:
				panel.panel_shape = PuzzlePanel.PanelShape.SKULL
			else:
				if RandomService.randi_channel('puzzles')%2==0:
					panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
					squares+=1
				else:
					panel.panel_shape = PuzzlePanel.PanelShape.TRIANGLE
					triangles+=1

## Set the colors
func panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.TRIANGLE:
			panel.set_color(Color.GREEN)
		_:
			panel.set_color(Color.RED)

## Change shapes or LOSE
func player_stepped_on(panel : PuzzlePanel) -> void:
	match panel.panel_shape:
		PuzzlePanel.PanelShape.SKULL:
			lose_game()
			return
		PuzzlePanel.PanelShape.SQUARE:
			squares-=1
			triangles+=1
			panel.panel_shape = PuzzlePanel.PanelShape.TRIANGLE
		PuzzlePanel.PanelShape.TRIANGLE:
			triangles-=1
			squares+=1
			panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
	# Win condition
	if squares == 0 or triangles == 0:
		win_game()

func get_game_text() -> String:
	return "Matching"
