extends Node
class_name ScoreSignal


@export var score_channel: StringName = &''
@export var node: NodePath
@export var signal_name := ''
@export var one_shot := false
@export var point_amount := 100


func _ready() -> void:
	if get_node(node).has_signal(signal_name):
		if one_shot:
			get_node(node).get(signal_name).connect(award_points, CONNECT_ONE_SHOT)
		else:
			get_node(node).get(signal_name).connect(award_points)

func award_points() -> void:
	ScoreTally.modify_score(score_channel, point_amount)
