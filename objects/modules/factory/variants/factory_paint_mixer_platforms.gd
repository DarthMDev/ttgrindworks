extends Node3D

func _ready() -> void:
	if RandomService.randi_channel('true_random') % 2 == 0:
		%treasure_chest.queue_free()
	else:
		%treasure_chest2.queue_free()
