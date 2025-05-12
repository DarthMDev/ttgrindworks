extends Node3D

signal s_game_won

const UI_SCENE := preload('res://objects/interactables/mole_stomp/mole_display.tscn')

@export var quota := 8:
	set(x):
		quota = x
		await NodeGlobals.until_ready(self)
		if mole_ui:
			mole_ui.get_node("MoleCount").text = "Moles Left: %s" % quota
@export var mole_popup_time_range := Vector2(6, 12)
@export var game_time: float = 60.0
@export var mole_games: Array[MoleStompGame] = []
@export var base_damage: int = -10
@export var door: CogDoor

@onready var start_quota: int = quota
@onready var chest_node: Node3D = %ChestSpawns

var mole_ui: Control

var moles_remaining := quota
var game_timer: Control
var game_started := false

var mole_task: Task

var damage: int

var tween: Tween:
	set(x):
		if tween and tween.is_valid():
			tween.kill()
		tween = x
var ui_tween: Tween:
	set(x):
		if ui_tween and ui_tween.is_valid():
			ui_tween.kill()
		ui_tween = x

func _ready() -> void:
	damage = Util.get_hazard_damage() + base_damage
	if door:
		door.add_lock()

func body_entered(body: Node3D) -> void:
	if body is Player and not game_started:
		start_game()

func start_game() -> void:
	hookup_moles()
	game_started = true
	make_game_timer()
	spawn_new_mole()

	mole_ui = UI_SCENE.instantiate()
	add_child(mole_ui)
	mole_ui.get_node("MoleCount").text = "Moles Left: %s" % quota

func make_game_timer() -> void:
	game_timer = Util.run_timer(game_time, Control.PRESET_BOTTOM_RIGHT)
	game_timer.timer.timeout.connect(lose_game)

func spawn_new_mole() -> void:
	var mole_game: MoleStompGame = RandomService.array_pick_random("mole_quadrant", mole_games)
	var mole: MoleHole = mole_game.get_random_mole()
	mole.force_cog_mole = true
	mole.mole_cog_boost_time = 2.5
	mole_task = Task.delayed_call(self, randf_range(mole_popup_time_range.x, mole_popup_time_range.y), spawn_new_mole)

func hookup_moles() -> void:
	for mole_game: MoleStompGame in mole_games:
		mole_game.s_managed_red_hit.connect(mole_hit)
		mole_game.start_game()
		for mole_hole: MoleHole in mole_game.get_all_moles():
			# Gears too big
			mole_hole.get_node("CogGears").process_material.initial_velocity_min = 2.5
			mole_hole.get_node("CogGears").process_material.initial_velocity_max = 5.0

func mole_hit() -> void:
	quota -= 1
	if quota <= 0:
		win_game()

func win_game() -> void:
	Util.get_player().quick_heal(10)
	spawn_winner_chests_for_winners_only()
	end_game()

func lose_game() -> void:
	if Util.get_player().stats.hp > 1:
		Util.get_player().quick_heal(damage)
		AudioManager.play_sound(Util.get_player().toon.yelp)

	end_game()

## Spawns chests for the winners of the game when they win the game
func spawn_winner_chests_for_winners_only() -> void:
	if is_instance_valid(chest_node):
		for child: Node3D in chest_node.get_children():
			child.add_child(Globals.DUST_CLOUD.instantiate())
			child.add_child(Globals.TREASURE_CHEST.instantiate())

func end_game() -> void:
	cancel_mole_task()
	for mole_game: MoleStompGame in mole_games:
		mole_game.disable_moles()
		mole_game.timer.stop()
	if mole_ui:
		mole_ui.queue_free()
		mole_ui = null
	if game_timer:
		game_timer.queue_free()
		game_timer = null
	if door:
		door.unlock()
	s_game_won.emit()

func cancel_mole_task() -> void:
	if mole_task:
		mole_task = mole_task.cancel()

func _exit_tree() -> void:
	cancel_mole_task()
