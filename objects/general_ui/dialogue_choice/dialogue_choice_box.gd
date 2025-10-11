@tool
extends "res://objects/battle/misc_battle_objects/pop_quiz/pop_quiz.gd"


var click_buffer: Control

func _ready() -> void:
	add_click_buffer()

func add_click_buffer() -> void:
	click_buffer = Control.new()
	click_buffer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(click_buffer)
	get_parent().move_child(click_buffer,get_parent().get_children().find(self))

func answer_selected(answer: String) -> void:
	super(answer)
	if click_buffer:
		click_buffer.queue_free()
