@tool
extends Control
class_name UIPanel

@export var title := "":
	set(x):
		if not is_node_ready(): return
		title_label.set_text.call_deferred(x)
	get:
		if not title_label: return ""
		return title_label.text
@export_multiline var body := "":
	set(x):
		if not is_node_ready(): return
		body_label.set_text(x)
	get:
		if not body_label: return ""
		return body_label.text
@export var cancelable := true:
	set(x):
		if not is_node_ready(): return
		cancel_button.visible = x
	get:
		if not cancel_button: return true
		return cancel_button.visible
@export var pop := true

@onready var panel := $Panel
@onready var title_label : Label = $Panel/Title
@onready var body_label : Label = $Panel/Body
@onready var cancel_button : GeneralButton = $Panel/CancelButton
@onready var animator : AnimationPlayer = $AnimationPlayer

var active := false
var click_buffer : Control

signal s_closed


func close() -> void:
	if not active : return
	
	active = false
	
	if pop:
		animator.play('pop_out')
		await animator.animation_finished
	
	if click_buffer: 
		click_buffer.queue_free()
	
	s_closed.emit()
	
	queue_free()

func on_resize() -> void:
	panel.size = size
	panel.pivot_offset = size/2.0

func _ready() -> void:
	on_resize()
	add_click_buffer()
	if pop:
		animator.play('pop_in')
		await animator.animation_finished
	
	active = true

func add_click_buffer() -> void:
	click_buffer = Control.new()
	click_buffer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_parent().add_child(click_buffer)
	get_parent().move_child(click_buffer,get_parent().get_children().find(self))

func set_property(node : Node, property : StringName, value : Variant) -> void:
	if not is_node_ready():
		await ready
	node.set(property,value) 

func get_property(node : Node, property : StringName) -> Variant:
	if not is_node_ready():
		await ready
	return node.get(property)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(click_buffer) and not click_buffer.is_queued_for_deletion():
			click_buffer.queue_free()
