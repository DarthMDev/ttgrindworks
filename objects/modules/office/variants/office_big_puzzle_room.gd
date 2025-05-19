extends Node3D

const MUSIC := "res://audio/music/encntr_skull_master.ogg"

@onready var shelf: Node3D = %law_bookshelf
@onready var shelf2: Node3D = %law_bookshelf2
@onready var puzzle_origin: Node3D = %PuzzleOrigin
@onready var button: CogButton = %CogButton

func _ready() -> void:
	setup_puzzle()

func setup_puzzle() -> void:
	var new_puzzle := get_random_puzzle()
	new_puzzle.grid_width = 9
	new_puzzle.grid_height = 15
	setup_game_specifics(new_puzzle)
	puzzle_origin.add_child(new_puzzle)
	new_puzzle.s_began_interaction.connect(block)
	new_puzzle.lose_battle = %BattleNode
	new_puzzle.s_win.connect(unblock)
	button.connect_to(new_puzzle)

func block() -> void:
	var block_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	block_tween.tween_callback(AudioManager.set_music.bind(load(MUSIC)))
	block_tween.tween_property(shelf, 'position:z', 0.0, 0.5)
	block_tween.tween_property(shelf2, 'position:z', 0.0, 0.5)
	block_tween.finished.connect(block_tween.kill)

func unblock() -> void:
	var block_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	block_tween.tween_callback(AudioManager.stop_music)
	block_tween.tween_property(shelf, 'position:z', 7.854, 0.5)
	block_tween.tween_property(shelf2, 'position:z', 7.854, 0.5)
	block_tween.finished.connect(block_tween.kill)

func setup_game_specifics(puzzle: LawbotPuzzleGrid) -> void:
	if puzzle is PuzzleSkullFinder:
		setup_skullfinder(puzzle)
	elif puzzle is PuzzleAvoidSkulls:
		setup_avoid(puzzle)

func setup_skullfinder(puzzle: PuzzleSkullFinder) -> void:
	puzzle.bomb_count = 32

func setup_avoid(puzzle: PuzzleAvoidSkulls) -> void:
	puzzle.skull_chance = 3

func get_random_puzzle() -> LawbotPuzzleGrid:
	var return_puzzle: LawbotPuzzleGrid
	while not return_puzzle:
		return_puzzle = Globals.random_puzzle
		if return_puzzle is PuzzleDragThree:
			return_puzzle = null
	return return_puzzle
