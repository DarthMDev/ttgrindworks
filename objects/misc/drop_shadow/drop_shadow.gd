extends RayCast3D

@export var force_hide := false

@onready var shadow := $Shadow

func _physics_process(_delta: float) -> void:
	if is_colliding():
		shadow.global_position.y = get_collision_point().y + 0.005
		if not visible:
			shadow.reset_physics_interpolation()
			if not force_hide: show()
	elif visible:
		hide()
