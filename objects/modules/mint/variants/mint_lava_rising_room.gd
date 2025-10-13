@tool
extends Node3D

@export var rise_height: float = 10.0:
	set(x):
		rise_height = x
		await NodeGlobals.until_ready(self)
		start_tween()
@export var rise_speed: float = 2.0:
	set(x):
		rise_speed = x
		if rise_tween and rise_tween.is_running():
			rise_tween.set_speed_scale(x)

@onready var lava_plane: MeshInstance3D = %LavaPlane

var rise_tween: Tween

func _ready() -> void:
	start_tween()

func start_tween() -> void:
	if rise_tween and rise_tween.is_running():
		rise_tween.kill()
	lava_plane.position.y = 0.0
	rise_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	rise_tween.tween_property(lava_plane, 'position:y', rise_height, 1.0)
	rise_tween.tween_property(lava_plane, 'position:y', 0.0, 1.0)
	rise_tween.set_speed_scale(rise_speed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		start_tween()
