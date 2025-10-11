extends Node3D

@onready var path := %BucketPath
@onready var blades := %FanBlades

func _process(delta: float) -> void:
	for bucket in path.get_children():
		bucket.progress_ratio += 0.09 * delta
