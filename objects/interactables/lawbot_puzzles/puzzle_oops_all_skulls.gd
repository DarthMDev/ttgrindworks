@tool
extends LawbotPuzzleGrid
class_name PuzzleAllSkulls




func initialize_game() -> void:
	# Set all panels to skull
	for i in grid.size():
		for j in grid[i].size():
			var panel : PuzzlePanel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.SKULL



func player_stepped_on(panel : PuzzlePanel) -> void:
	lose_game()
