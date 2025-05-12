@tool  # <-- To show your puzzle in the editor, make your script a @tool script!
extends Node3D
class_name LawbotPuzzleGrid

## Lose Type
## Battle starts the attached cog battle
## Explode causes an explosion that damages the player
## Custom will do nothing. Just sends out the s_lose signal for you to whatever w/
enum LoseType {
	BATTLE,
	EXPLODE,
	CUSTOM
}

@export_tool_button('Re-generate Puzzle (for custom properties changed)', 'EditorPlugin') var do_setup = func():
	if is_node_ready():
		_setup()

@export_group('Visuals')
## Grid Size
@export_range(1, 20, 1, "or_less", "or_greater") var grid_width := 7:
	set(new):
		grid_width = new
		if is_node_ready():
			_setup()
@export_range(1, 20, 1, "or_less", "or_greater") var grid_height := 7:
	set(new):
		grid_height = new
		if is_node_ready():
			_setup()
# DONT USE: Old property "beam height", use beam origin instead
@export_storage var beam_height := 2.5:
	set(new):
		beam_height = new
		if use_beam_height:
			use_beam_height = false
			beam_origin = Vector3(0, beam_height, 0)
@export_storage var use_beam_height := true
@export var beam_origin := Vector3(0, 2.5, 0):
	set(new):
		beam_origin = new
		if is_node_ready():
			_setup()
			
@export_group('Player Interaction')
@export var lose_type := LoseType.BATTLE
@export var lose_battle : BattleNode
@export var explosion_damage := -5
@export var should_heal_player := true

## Locals
var grid := []
var player_cells : Array[PuzzlePanel] = []
var panel_node : Node3D
var beam_node : Node3D
var LABEL: PackedScene

const BLUE := Color("4d4dff")

## Signals
signal s_win
signal s_lose
signal s_began_interaction

var began_interaction := false:
	set(x):
		began_interaction = x
		if began_interaction:
			s_began_interaction.emit()

func _init():
	if Engine.is_editor_hint(): return
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'LABEL': 'res://objects/interactables/lawbot_puzzles/puzzle_label.tscn',
	})

func _ready() -> void:
	_setup()

func _setup() -> void:
	for child in get_children():
		child.free()
	grid.clear()
	
	# Create nodes for storing the beams and panels
	panel_node = Node3D.new()
	add_child(panel_node)
	panel_node.name = "Panels"
	beam_node = Node3D.new()
	add_child(beam_node)
	beam_node.name = "Beams"
	
	# Fill the grid and start the game
	fill_grid()
	initialize_game()

## Fills the grid with panels
func fill_grid() -> void:
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			var panel := PuzzlePanel.new()
			panel_node.add_child(panel)
			panel.position = Vector3(1*i,0,1*j)
			grid[i].append(panel)
			panel.pos = Vector2i(i,j)
			panel.s_player_entered.connect(_pre_player_stepped_on)
			panel.s_player_exited.connect(player_stepped_off)
			panel.s_player_entered.connect(_add_player)
			panel.s_player_exited.connect(_remove_player)
			panel.s_shape_changed.connect(panel_shape_changed)
			
			# Create the beam for the panel
			var beam := PanelBeam.new()
			beam_node.add_child(beam)
			beam.connect_panel(panel)
			beam.position = Vector3(
				beam_origin.x + (float(grid_width) / 2.0),
				beam_origin.y,
				beam_origin.z + (float(grid_height) / 2.0),
			)

## Overwrite this function to initialize your game
func initialize_game() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.SKULL

func _pre_player_stepped_on(_panel: PuzzlePanel) -> void:
	if not began_interaction:
		began_interaction = true
		show_game_title()
	player_stepped_on(_panel)

func show_game_title() -> void:
	var label : Control = LABEL.instantiate()
	add_child(label)
	label.set_text(get_game_text())

## Overwrite these functions to react to player movement
func player_stepped_on(_panel : PuzzlePanel) -> void:
	pass
func player_stepped_off(_panel : PuzzlePanel) -> void:
	pass
	
## Overwrite this function to change the colors of shapes
func panel_shape_changed(_panel : PuzzlePanel,_shape : PuzzlePanel.PanelShape) -> void:
	pass

## DO NOT OVERWRITE
func _add_player(panel : PuzzlePanel) -> void:
	if panel not in player_cells:
		player_cells.append(panel)
func _remove_player(panel : PuzzlePanel) -> void:
	if panel in player_cells:
		player_cells.erase(panel)

func lose_game() -> void:
	if Engine.is_editor_hint():
		return
	
	s_lose.emit()
	if lose_type == LoseType.BATTLE:
		if not lose_battle:
			push_error("ERR: NO BATTLE NODE SPECIFIED FOR PUZZLE")
			return
		lose_battle.show()
		lose_battle.player_entered(Util.get_player())
		queue_free()
	elif lose_type == LoseType.EXPLODE:
		# Make Player slip backwards
		var player := Util.get_player()
		AudioManager.play_sound(player.toon.yelp)
		player.last_damage_source = "the Head of Security"
		player.quick_heal(Util.get_hazard_damage() + explosion_damage)
		# Only do the animation if the player is alive
		if player.stats.hp > 0:
			player.state = Player.PlayerState.STOPPED
			player.set_animation('slip_backward')
		
		# Do Kaboom
		AudioManager.play_sound(load('res://audio/sfx/battle/cogs/ENC_cogfall_apart.ogg'))
		var kaboom := Sprite3D.new()
		kaboom.render_priority = 1
		kaboom.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		kaboom.texture = load('res://models/props/gags/tnt/kaboom.png')
		add_child(kaboom)
		kaboom.global_position = player.global_position
		kaboom.scale *= 0.25
		var kaboom_tween := create_tween()
		kaboom_tween.tween_property(kaboom,'pixel_size',.05,0.25)
		await kaboom_tween.finished
		kaboom_tween.kill()
		kaboom.queue_free()
		
		# Free player (only if they're alive)
		if player.stats.hp > 0:
			await player.animator.animation_finished
			player.state = Player.PlayerState.WALK
			player.do_invincibility_frames(1.0)

func get_all_panels() -> Array[PuzzlePanel]:
	var all_panels : Array[PuzzlePanel] = []
	for i in grid.size():
		for j in grid[i].size():
			all_panels.append(grid[i][j])
	return all_panels

func get_panel(x : int, y: int) -> PuzzlePanel:
	return grid[x][y]

func get_adjacent_panels(x: int,y: int) -> Array[PuzzlePanel]:
	var positions : Array[Vector2i] = [
		Vector2i(x-1,y-1),
		Vector2i(x,y-1),
		Vector2i(x+1,y-1),
		Vector2i(x-1,y),
		Vector2i(x+1,y),
		Vector2i(x-1,y+1),
		Vector2i(x,y+1),
		Vector2i(x+1,y+1)
	]
	
	var panels : Array[PuzzlePanel] = []
	for pos in positions:
		if grid.size() > pos.x:
			if grid[pos.x].size() > pos.y:
				panels.append(grid[pos.x][pos.y])
	return panels

func get_panel_coords(panel : PuzzlePanel) -> Vector2i:
	for i in grid.size():
		for j in grid[i].size():
			if grid[i][j] == panel:
				return Vector2(i, j)
	return Vector2.ZERO

func get_panels_in_row(row_num : int) -> Array[PuzzlePanel]:
	var panels : Array[PuzzlePanel] = []
	for i in grid_width:
		panels.append(grid[i][row_num])
	return panels

func get_panels_in_column(column_num : int) -> Array[PuzzlePanel]:
	var panels : Array[PuzzlePanel] = []
	for i in grid_width:
		panels.append(grid[column_num][i])
	return panels

func win_game() -> void:
	if Engine.is_editor_hint():
		return
		
	s_win.emit()
	if lose_battle:
		lose_battle.queue_free()
	queue_free()
	if Util.get_player() and should_heal_player:
		Util.get_player().quick_heal(-explosion_damage)
		AudioManager.play_sound(load("res://audio/sfx/battle/gags/toonup/sparkly.ogg"))

func connect_button(button : CogButton) -> void:
	button.s_pressed.connect(func(_button : CogButton): win_game())
	s_win.connect(button.press)

func get_game_text() -> String:
	return ""
