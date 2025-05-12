extends Node3D

const REINFORCEMENTS := preload("res://objects/battle/battle_resources/cog_attacks/resources/call_reinforcements.tres")

@onready var mole_cog : Cog = $BattleNode/MoleCog
@onready var mole_hill : MoleHole = $mole_hole
@onready var battle : BattleNode = $BattleNode


func _ready() -> void:
	
	await battle.s_battle_initialized
	await BattleService.s_round_started
	bring_in_reinforcements()

func bring_in_reinforcements() -> void:
	var action := REINFORCEMENTS.duplicate()
	action.user = mole_cog
	action.cog_amount = 3
	action.targets = [mole_cog]
	BattleService.ongoing_battle.round_end_actions.append(action)

## For intro cutscene
func get_camera_angle(angle : String) -> Transform3D:
	return $CameraAngles.find_child(angle).global_transform

func get_char_position(pos : String) -> Vector3:
	return $CharPositions.find_child(pos).global_position
