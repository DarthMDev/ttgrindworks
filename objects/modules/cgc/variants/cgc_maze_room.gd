extends Node3D
class_name CGCMaze

const MAZE_SCENE := preload("res://objects/modules/cgc/variants/cgc_maze_generator.tscn")
const BASE_TIME := 45.0
const PER_MAZE_TIME := 25.0


## Exit cells
const BOTTOM_CELL := Vector2i(7,3)
const TOP_CELL := Vector2i(0,3)
const LEFT_CELL := Vector2i(4,0)
const RIGHT_CELL := Vector2i(4,6)

enum MazeSide {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT
}

## Maze size is exponential, it is the length/width of the grid
## Special case for 0 which is the 2-parter maze
@export var maze_size := -1
@export var base_damage := -5

## Child References
@onready var maze_entrance := $MazeEntrance
@onready var maze_exit := $MazeExit

## Locals
var grid_size := Vector2i(1,1)
var maze_grid := {}
var game_timer: Control
var active := false
var lose_pos: Node3D
var game_valid := true


func _ready() -> void:
	generate()

#region MAZE GENERATION
func generate() -> void:
	# Randomized maze size
	if maze_size == -1:
		maze_size = RNG.channel(RNG.ChannelMazeSizes).randi() % 3
	
	# Calculate the grid size
	# TTO had a non exponentially inclined maze type (the 2 part mazes)
	# So we can create a special kind of maze for that 
	if maze_size == 0:
		grid_size = Vector2i(1,2)
	else:
		grid_size *= maze_size
	
	# Add each maze
	for i in grid_size.x:
		for j in grid_size.y:
			
			# Instantiate the maze scene
			var new_maze := MAZE_SCENE.instantiate()
			add_child(new_maze)
			new_maze.get_node('RoomAreaShape').reparent($RoomArea)
			new_maze.name = "Maze" + str(maze_grid.keys().size() + 1)
			
			# Add the maze scene to the grid dict
			maze_grid[Vector2i(i, j)] = new_maze
			
			# Take what we need from the first maze
			if Vector2i(i, j) == Vector2i(0, 0):
				# Get the true room entrance
				new_maze.get_node('ENTRANCE').reparent(self)
				new_maze.get_node('EntranceCollision').reparent(maze_entrance)
			# For all other mazes:
			else:
				# Delete the entrance
				new_maze.entrance_area.queue_free()
				# Find adjacent mazes
				var connected_mazes := get_connecting_mazes(Vector2i(i, j))
				for maze_vec in connected_mazes:
					var connection_side := get_connection_side(maze_vec, Vector2i(i, j))
					place_maze(maze_grid[maze_vec],new_maze,connection_side)
			
			# For the final maze:
			if i == grid_size.x - 1 and j == grid_size.y - 1:
				# Get the true room exit
				new_maze.get_node('EXITS/EXIT').reparent(self)
				# Move the battle into position
				$BattleNode.reparent(new_maze,false)
				lose_pos = new_maze.get_node('LosePos')
				new_maze.get_node('ExitCollision').reparent(maze_exit)
			# Delete the battle area of all other mazes
			else:
				new_maze.battle_area.queue_free()
	
	# Fill each maze
	for key in maze_grid.keys():
		await maze_grid[key].fill_maze()
	
	# Iterate through the mazes again to generate the mazes
	for i in grid_size.x:
		for j in grid_size.y:
			# Get the maze in question
			var maze_vec := Vector2i(i, j)
			var maze: Node3D = maze_grid[maze_vec]
			
			# Mark true maze entrance and exit for deletion
			if maze_vec == Vector2i(0, 0):
				maze.get_unit(BOTTOM_CELL).get_node('HedgeFront').hide()
			if maze_vec == Vector2i(grid_size.x - 1, grid_size.y - 1):
				maze.get_unit(TOP_CELL).get_node('HedgeBack').hide()
			
			# For every maze that is not the entrance
			if not maze_vec == Vector2i(0, 0):
				# Find the adjacent mazes
				var connected_mazes := get_connecting_mazes(Vector2i(i, j))
				for vec in connected_mazes:
					var connection_side := get_connection_side(vec, Vector2i(i, j))
					connect_mazes(maze_grid[vec],maze,connection_side)
			
	# Finally, generate each maze as a coroutine
	# "Optimization" and all that.
	for key in maze_grid.keys():
		await maze_grid[key].generate_maze()


## Places two mazes next to each other geographically
func place_maze(maze_1: Node3D, maze_2: Node3D, side: MazeSide) -> void:
	# Find the two exit nodes
	var exit1: Node3D
	var exit2: Node3D

	match side:
		MazeSide.TOP:
			exit1 = maze_1.get_node('EXITS/ExitTop')
			exit2 = maze_2.get_node('EXITS/ExitBottom')
		MazeSide.BOTTOM:
			exit1 = maze_1.get_node('EXITS/ExitBottom')
			exit2 = maze_2.get_node('EXITS/ExitTop')
		MazeSide.LEFT:
			exit1 = maze_1.get_node('EXITS/ExitLeft')
			exit2 = maze_2.get_node('EXITS/ExitRight')
		MazeSide.RIGHT:
			exit1 = maze_1.get_node('EXITS/ExitRight')
			exit2 = maze_2.get_node('EXITS/ExitLeft')

	# Check the positional difference for maze 2 to connect to maze 1
	var old_pos: Vector3 = exit2.global_position
	exit2.global_position = exit1.global_position
	var pos_diff: Vector3 = exit2.global_position - old_pos
	exit2.global_position = old_pos
	maze_2.global_position += pos_diff

## Connects maze 2 to maze 1 on specified side
## The side refers to maze 1's connection side
func connect_mazes(maze_1: Node3D, maze_2: Node3D, side: MazeSide) -> void:
	# And open the mazes on connected side
	var erase_hedges: Array[Node3D] = []
	match side:
		MazeSide.TOP:
			erase_hedges.append_array([maze_1.get_unit(TOP_CELL).get_node('HedgeBack'), maze_2.get_unit(BOTTOM_CELL).get_node('HedgeFront')])
		MazeSide.BOTTOM:
			erase_hedges.append_array([maze_1.get_unit(BOTTOM_CELL).get_node('HedgeBack'), maze_2.get_unit(TOP_CELL).get_node('HedgeFront')])
		MazeSide.LEFT:
			erase_hedges.append_array([maze_1.get_unit(LEFT_CELL).get_node('HedgeLeft'), maze_2.get_unit(RIGHT_CELL).get_node('HedgeRight')])
		MazeSide.RIGHT:
			erase_hedges.append_array([maze_1.get_unit(RIGHT_CELL).get_node('HedgeRight'), maze_2.get_unit(LEFT_CELL).get_node('HedgeLeft')])
	
	for hedge in erase_hedges:
		hedge.hide()

func get_connecting_mazes(from: Vector2i) -> Array[Vector2i]:
	# Get all the potential vectors
	var return_arr : Array[Vector2i] = []
	return_arr.append(Vector2i(from.x - 1, from.y))
	return_arr.append(Vector2i(from.x + 1, from.y))
	return_arr.append(Vector2i(from.x, from.y - 1))
	return_arr.append(Vector2i(from.x, from.y + 1))
	
	# Remove all non-existent maze keys from the array
	for i in range(return_arr.size() - 1, -1, -1):
		if not maze_grid.has(return_arr[i]):
			return_arr.remove_at(i)
	
	# Return the found mazes
	return return_arr

## Returns the maze side for when vec2 is to be connected to vec1
func get_connection_side(vec1: Vector2i, vec2: Vector2i) -> MazeSide:
	if vec1.x < vec2.x: return MazeSide.RIGHT
	elif vec1.x > vec2.x: return MazeSide.LEFT
	elif vec1.y < vec2.y: return MazeSide.TOP
	else: return MazeSide.BOTTOM

## Returns a maze's unit at specified pos
func get_maze_unit(maze: Node3D, grid_pos: Vector2i) -> Node3D:
	return maze.get_unit(grid_pos)
#endregion

#region MAZE GAME

func maze_entered(body: Node3D) -> void:
	if not body is Player or not game_valid: return
	
	# Start the game
	var game_time := BASE_TIME + (PER_MAZE_TIME * (maze_grid.size() - 1))
	game_timer = Util.run_timer(game_time)
	active = true
	game_timer.timer.timeout.connect(lose_game)
	game_valid = false
	print("Maze game started.")

func win_game(body: Node3D) -> void:
	print("Maze game won.")
	if not active or not body is Player: return
	body.quick_heal(-base_damage)
	active = false
	if game_timer:
		game_timer.queue_free()

func lose_game() -> void:
	print("Maze Game Lost.")
	if not Util.get_player(): return
	
	active = false
	
	var player := Util.get_player()
	player.last_damage_source = "Directions"
	player.quick_heal(Util.get_hazard_damage(base_damage))
	AudioManager.play_sound(player.toon.yelp)
	
	# If player is dead, no need to continue
	if player.stats.hp < 0:
		return
	
	player.state = Player.PlayerState.STOPPED
	await player.teleport_out()
	player.global_position = lose_pos.global_position
	player.teleport_in(true)

#endregion
