@tool
extends LawbotPuzzleGrid
class_name PuzzleMemory

@export var strike_count := 4

const SFX_REVEAL_SQUARE := preload("res://audio/sfx/objects/spotlight/LB_laser_beam_on_2.ogg")
const SFX_HIDE_SQUARE := preload("res://audio/sfx/misc/LB_capacitor_discharge_3.ogg")

var correct_path : Array[Vector2i] = []
var strike_index := 0
var title_shown := false

var reveal_tween : Tween

signal s_strike(index : int)


func _ready() -> void:
	super()
	generate_correct_path()

func initialize_game() -> void:
	for i in grid.size():
		for j in grid[i].size():
			var panel = grid[i][j]
			panel.panel_shape = PuzzlePanel.PanelShape.QUESTIONMARK

func generate_correct_path() -> void:
	# Generate a valid path from one end to the other
	correct_path.clear()
	var current_pos = Vector2i(RandomService.randi_channel("true_random") % grid_width, 0)
	correct_path.append(current_pos)
	while current_pos.y < grid_height - 1:
		var next_dir : int
		if correct_path.size() == 1:
			next_dir = 0
		else:
			next_dir = randi() % 3
		current_pos = move_in_direction(next_dir, current_pos)

## 0 for up, 1 for left, 2 for right
## NO MOVING DOWN. that's mean and evil
func move_in_direction(dir : int, current_pos : Vector2i) -> Vector2i:
	var move_again := true
	var prev_pos := current_pos
	var moves := 0
	var positions_to_append : Array[Vector2i] = []
	while move_again:
		moves += 1
		
		# Make the move for real
		match dir:
			0: current_pos.y += 1
			1: current_pos.x -= 1
			2: current_pos.x += 1
		
		# Don't allow retreading
		if current_pos in correct_path:
			return prev_pos
		
		# Don't allow off-grid travel
		if current_pos.x >= grid_width or current_pos.x < 0:
			return prev_pos
		
		# Append this position to our list
		positions_to_append.append(current_pos)
		
		# If end point is reached, break early
		if current_pos.y == grid_height - 1:
			break
		
		# Always move in a particular direction twice
		if moves > 1:
			move_again = false
	
	for pos in positions_to_append:
		correct_path.append(pos)
	return current_pos

func player_stepped_on(_panel : PuzzlePanel) -> void:
	if _panel.panel_shape == PuzzlePanel.PanelShape.SKULL:
		return
	if _panel.pos in correct_path:
		_panel.panel_shape = PuzzlePanel.PanelShape.SQUARE
	else:
		_panel.panel_shape = PuzzlePanel.PanelShape.SKULL
		if strike_index >= strike_count - 1:
			lose_game()
		else:
			strike_index += 1
			s_strike.emit(strike_index)
	if _panel.pos.y == grid_height - 1:
		win_game()

func player_stepped_off(_panel : PuzzlePanel) -> void:
	pass

func connect_button(button : CogButton) -> void:
	button.s_pressed.connect(show_correct_path)
	button.s_retracted.connect(hide_correct_path)

func show_correct_path(_button) -> void:
	var sfx_pitch_increase = 0.05
	reveal_tween = create_tween()
	for i in range(correct_path.size()):
		var pos = correct_path[i]
		reveal_tween.tween_callback(_reveal_panel.bind(pos))
		reveal_tween.tween_callback(
			func():
				var audio_player = AudioManager.play_sound(SFX_REVEAL_SQUARE)
				audio_player.pitch_scale += sfx_pitch_increase * i
		)
		reveal_tween.tween_interval(0.1)
	
	if not title_shown:
		title_shown = true
		show_game_title()

func panel_shape_changed(panel : PuzzlePanel, shape : PuzzlePanel.PanelShape) -> void:
	match shape:
		PuzzlePanel.PanelShape.SQUARE: panel.set_color(Color.GREEN)
		PuzzlePanel.PanelShape.QUESTIONMARK: panel.set_color(Color("4d4dff"))
		PuzzlePanel.PanelShape.SKULL: panel.set_color(Color.RED)

func hide_correct_path(_button) -> void:
	if reveal_tween:
		reveal_tween.kill()
	for pos in correct_path:
		var panel = grid[pos.x][pos.y]
		panel.panel_shape = PuzzlePanel.PanelShape.QUESTIONMARK
	AudioManager.play_sound(SFX_HIDE_SQUARE)

func _reveal_panel(pos : Vector2i) -> void:
	var panel = grid[pos.x][pos.y]
	panel.panel_shape = PuzzlePanel.PanelShape.SQUARE

func get_game_text() -> String:
	return "Pathfinder"

func _pre_player_stepped_on(_panel: PuzzlePanel) -> void:
	if not began_interaction:
		began_interaction = true
	if not title_shown:
		title_shown = true
		show_game_title()
	player_stepped_on(_panel)
