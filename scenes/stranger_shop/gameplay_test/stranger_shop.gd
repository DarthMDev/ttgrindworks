extends Node3D


func _ready() -> void:
	if not is_instance_valid(Util.get_player()):
		await Util.s_player_assigned
	Util.get_player().global_position = %PlayerSpawn.global_position
	Util.get_player().teleport_in(true)
	Util.get_player().camera.make_current()
	Util.get_player().stats.stranger_chance = 0.0
