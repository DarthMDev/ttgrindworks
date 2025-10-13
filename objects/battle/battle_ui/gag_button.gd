extends TextureButton
class_name GagButton

const DEFAULT_COLOR := Color("00a1ff")
const DISABLED_COLOR := Color('2e2e2e')

@onready var image_rect := $Image
@onready var label := $ButtonText
@onready var count_label := $CountLabel

@export var image: Texture2D:
	set(x):
		if not is_node_ready() or not x:
			return
		image_rect.texture = x
		image = x

@export var text: String

@onready var click_sfx = preload('res://audio/sfx/ui/Click.ogg')
@onready var hover_sfx = preload("res://audio/sfx/ui/GUI_rollover.ogg")

signal s_enabled
signal s_disabled

var default_color := DEFAULT_COLOR:
	set(x):
		default_color = x
		if not disabled:
			self_modulate = x

func _ready():
	label.text = text
	mouse_entered.connect(hover)

func hover() -> void:
	AudioManager.play_sound(hover_sfx, 6.0)

func set_count(number: int):
	count_label.set_text(str(number))

func disable():
	if disabled:
		return
	disabled = true
	self_modulate = DISABLED_COLOR
	s_disabled.emit()

func enable():
	if not disabled:
		return
	disabled = false
	self_modulate = default_color
	s_enabled.emit()

func button_down():
	AudioManager.play_sound(click_sfx)
