@tool
extends Node3D

@export var paint_streams: Array[Node3D]
@export var paint_mat: StandardMaterial3D
@export var scroll_speed := -3.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	for paint_stream: Node3D in paint_streams:
		paint_stream.get_node("MeshInstance3D/Area3D").body_entered.connect(paint_stream_entered)

func _process(delta: float) -> void:
	if paint_mat: 
		paint_mat.uv1_offset.y += scroll_speed * delta

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if paint_mat:
			paint_mat.uv1_offset.y = 0

func paint_stream_entered(body: Node3D) -> void:
	if body is Player:
		if body.state == Player.PlayerState.WALK:
			body.last_damage_source = "a Paint Stream"
			body.quick_heal(Util.get_hazard_damage(-5))
