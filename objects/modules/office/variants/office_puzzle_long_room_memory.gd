extends Node3D

const SPARK_SFX := preload("res://audio/sfx/battle/cogs/misc/LB_sparks_1.ogg")

@onready var battle : BattleNode = %BattleNode
@onready var puzzle : PuzzleMemory = %PuzzleMemory


func strike_added(index : int) -> void:
	var cog := battle.cogs[index - 1]
	bring_it_to_life(cog)

func bring_it_to_life(cog : Cog) -> void:
	AudioManager.play_sound(SPARK_SFX)
	cog.set_animation('drop')
	cog.animator_seek(3.0)
	cog.show()

func on_puzzle_lose() -> void:
	for cog in battle.cogs:
		cog.show()
	bring_it_to_life(battle.cogs[-1])
	battle.body_entered(Util.get_player())
	puzzle.queue_free()

func on_game_win() -> void:
	clean_battle()
	puzzle.queue_free()
	if battle.cogs.size() > 0:
		battle.body_entered(Util.get_player())

func clean_battle() -> void:
	for cog : Cog in battle.cogs.duplicate():
		if not cog.visible:
			battle.cogs.erase(cog)
			cog.queue_free()

func show_puzzle(_button) -> void:
	var player := Util.get_player()
	CameraTransition.from_current(self, $PanCamera, 1.5)

func button_stepped_off(_button) -> void:
	if not get_viewport().get_camera_3d() == Util.get_player().camera.camera:
		CameraTransition.from_current(self, Util.get_player().camera.camera, 1.5)
