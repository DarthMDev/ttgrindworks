@tool
extends Control

const GENERAL_BUTTON := "res://objects/general_ui/general_button/general_button.tscn"
const ALPHABET := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const COLORS := [Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE]

signal s_answer_selected(answer: String)


@export var question := "":
	set(x):
		if not is_node_ready():
			await ready
		$QuestionLabel.set_text(x)
	get:
		return $QuestionLabel.text
@export var answers: Array[String] = []:
	set(x):
		if not is_node_ready():
			await ready
		answers = x
		set_answers(x)

@onready var question_label := $QuestionLabel
@onready var answer_base := $Answer
@onready var answer_node := $AnswerNode


func set_answers(answer_arr: Array[String]) -> void:
	for child in $AnswerNode.get_children():
		child.queue_free()
	for answer in answer_arr:
		var new_answer := $Answer.duplicate()
		new_answer.get_node('Panel/Label').set_text(answer)
		new_answer.show()
		$AnswerNode.add_child(new_answer)
		new_answer.get_node('GeneralButton').text = ALPHABET[answer_arr.find(answer)]
		new_answer.get_node('GeneralButton').pressed.connect(answer_selected.bind(answer))
		var color_index: int = answer_arr.find(answer) % 4
		new_answer.get_node('GeneralButton').self_modulate = COLORS[color_index]
	size.y = 160.0 + ($Answer.size.y*answer_arr.size())
	$AnswerNode.size.y = $Answer.size.y * answer_arr.size()
	position = (Vector2(get_viewport().get_visible_rect().size)-size)/2

func answer_selected(answer: String) -> void:
	s_answer_selected.emit(answer)
	queue_free()
