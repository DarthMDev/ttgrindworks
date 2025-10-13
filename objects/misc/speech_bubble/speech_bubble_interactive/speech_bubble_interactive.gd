@tool
extends SpeechBubble


const ARROW_ICONS: Dictionary[String, Texture2D] = {
	"up": preload("res://ui_assets/general/Horiz_Arrow_UP.png"),
	"down": preload("res://ui_assets/general/Horiz_Arrow_DN.png"),
	"hover": preload("res://ui_assets/general/Horiz_Arrow_Rllvr.png"),
}

const HOVER_COLOR := Color.SKY_BLUE
const DOWN_COLOR := Color.DEEP_SKY_BLUE

@export_multiline var dialogue: Array[String] = []
@export var write_out_text := false

var character: Node
var dialogue_index := -1
var mouse_hovered := false
var clicked_down := false
var clickable := true:
	set(x):
		await NodeGlobals.until_ready(self)
		clickable = x
		%Arrow.visible = x
var writeout_tween: Tween

signal s_dialogue_finished


func _ready() -> void:
	if not dialogue.is_empty():
		increment_dialogue()

func on_mouse_entered() -> void:
	mouse_hovered = true

func on_mouse_exited() -> void:
	mouse_hovered = false

func on_bubble_clicked() -> void:
	if clickable:
		increment_dialogue()

func increment_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue.size():
		s_dialogue_finished.emit()
		queue_free()
		return
	set_phrase(dialogue[dialogue_index])

func set_phrase(phrase: String) -> void:
	set_text(phrase)
	if write_out_text:
		do_text_tween()

func set_dialogue(new_dial: Array[String]) -> void:
	dialogue_index = -1
	dialogue = new_dial
	increment_dialogue()

func set_text_color(color: Color) -> void:
	label.add_theme_color_override('default_color', color)

## TODO
func do_text_tween() -> void:
	pass

func set_text(_text: String) -> void:
	super(_text)
	
	%Arrow.global_position = %ArrowPos.global_position
	%Arrow.position -= %Arrow.size * 1.2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.button_index == MOUSE_BUTTON_LEFT: return
		
		if event.pressed and mouse_hovered:
			clicked_down = true
		elif not event.pressed:
			if mouse_hovered:
				on_bubble_clicked()
			clicked_down = false

func _process(delta: float) -> void:
	super(delta)
	
	if clicked_down:
		set_text_color(DOWN_COLOR)
		%Arrow.set_texture(ARROW_ICONS['down'])
	elif mouse_hovered:
		set_text_color(HOVER_COLOR)
		%Arrow.set_texture(ARROW_ICONS['hover'])
	else:
		set_text_color(Color.BLACK)
		%Arrow.set_texture(ARROW_ICONS['up'])
