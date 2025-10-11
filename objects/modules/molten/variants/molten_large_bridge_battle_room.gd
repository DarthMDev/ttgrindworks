extends Node3D

@onready var path := %Path3D

func _ready() -> void:
	var move_tween = create_tween().set_loops()
	move_tween.tween_property($Elevator/Platform, "position", $Elevator/Top.position, 0.2)
	move_tween.tween_property($Elevator/Platform, "position", $Elevator/Bottom.position, 2.9)
	move_tween.tween_interval(4.0)
	move_tween.tween_property($Elevator/Platform, "position", $Elevator/Top.position, 2.9)
	move_tween.tween_property($Elevator/Platform, "position", $Elevator/TopTop.position, 0.2)
	move_tween.tween_interval(4.0)

func _process(delta: float) -> void:
	for bucket in path.get_children():
		bucket.progress_ratio += .04 * delta
