extends "res://objects/modules/mint/base_rooms/mint_conveyor_room.gd"


func _physics_process(delta: float) -> void:
	var free_objs_a: Array = []
	var free_objs_b: Array = []
	var free_threshold := -7.0
	# Move all existing objects
	for obj: Node3D in objs_a:
		obj.position.x -= cb_lower.speed * delta
		if obj.position.x <= free_threshold:
			free_objs_a.append(obj)
	for obj: Node3D in objs_b:
		obj.position.x -= cb_upper.speed * delta
		if obj.position.x <= free_threshold:
			free_objs_b.append(obj)

	for obj: Node3D in free_objs_a:
		obj.queue_free()
		objs_a.erase(obj)
	for obj: Node3D in free_objs_b:
		obj.queue_free()
		objs_b.erase(obj)

func get_random_object_time() -> float:
	return RNG.channel(RNG.ChannelMintConveyor).randf_range(1.0, 3.0)

func lower_ramp(_x=null) -> void:
	pass

func get_random_rotation() -> float:
	return -90.0

func get_random_scale() -> Vector3:
	return Vector3.ONE

func spawn_random_obj(side: String) -> void:
	if side == "b": return
	else: super(side)
