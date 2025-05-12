@tool
extends LawbotPuzzleGrid
class_name PuzzleSkullBounce

@export var skull_count := 1
@export var tick_rate := 4.0

class SkullObject :
	var position := Vector2i(0,0)
	var velocity := Vector2i(1,1)
	
	func move(grid : LawbotPuzzleGrid) -> Vector2:
		if position.x + velocity.x > grid.grid_width - 1 or position.x + velocity.x < 0:
			velocity.x = -velocity.x
			return move(grid)
		elif position.y + velocity.y > grid.grid_height - 1 or position.y + velocity.y < 0:
			velocity.y = -velocity.y
			return move(grid)
		position += velocity
		return position 
	
	func make_move(grid : PuzzleSkullBounce) -> void:
		grid.move_skull(self)

var skulls : Array[SkullObject] = []


## Overwrite this function to initialize your game
func initialize_game() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.DOT
	
	# Create tick timer
	var timer := Timer.new()
	timer.wait_time = 1.0 / tick_rate
	add_child(timer)
	timer.start()
	
	# Initialize skulls
	for i in skull_count:
		var skull := create_skull()
		timer.timeout.connect(skull.make_move.bind(self))
		skulls.append(skull)

func move_skull(skull : SkullObject) -> void:
	var old_pos := skull.position
	var new_pos := skull.move(self)
	var new_panel : PuzzlePanel = grid[new_pos.x][new_pos.y]
	new_panel.panel_shape = PuzzlePanel.PanelShape.SKULL
	
	for s in skulls:
		if s.position == old_pos:
			return
	
	var old_panel : PuzzlePanel = grid[old_pos.x][old_pos.y]
	old_panel.panel_shape = PuzzlePanel.PanelShape.DOT
	

func create_skull() -> SkullObject:
	var skull := SkullObject.new()
	skull.position = Vector2i(RandomService.randi_channel('puzzles') % grid_width, RandomService.randi_channel('puzzles') % grid_height)
	skull.velocity = Vector2i(RandomService.array_pick_random('true_random', [-1, 1]), RandomService.array_pick_random('true_random', [-1, 1]))
	return skull


func player_stepped_on(panel : PuzzlePanel) -> void:
	if panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		lose_game()

## Overwrite this function to change the colors of shapes
func panel_shape_changed(panel : PuzzlePanel,shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.SKULL: panel.set_color(Color.RED)
		PuzzlePanel.PanelShape.DOT: panel.set_color(Color.WHITE)
	
	if shape == PuzzlePanel.PanelShape.SKULL and panel in player_cells:
		lose_game()

func get_game_text() -> String:
	return "Skull Bounce!"
