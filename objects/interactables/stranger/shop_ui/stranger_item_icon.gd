@tool
extends VBoxContainer


const SCALE_UP := Vector2(1.1, 1.1)
const STANDARD_CHAR_LIMIT := 11
const STANDARD_FONT_SIZE := 20
const MIN_FONT_SIZE := 10

@export_range(0, 8) var price: int = 1:
	set(x):
		if not is_node_ready():
			await ready
		price = x
		update_price()

@export var item: Item:
	set(x):
		if not is_node_ready():
			await ready
		item = x
		setup_item()

@onready var name_label: Label = %ItemName
@onready var icon: TextureRect = %ItemIcon

var scale_tween: Tween
var sfx_hover: AudioStream:
	get: return GameLoader.load("res://audio/sfx/ui/GUI_rollover.ogg")
var sfx_click: AudioStream:
	get: return GameLoader.load("res://audio/sfx/ui/Click.ogg")

signal s_icon_clicked


func setup_item() -> void:
	if not item:
		hide()
		return
	
	price = (item.qualitoon as int) + 1
	
	# Other setup
	name_label.set_text(item.item_name)
	if name_label.text.length() > STANDARD_CHAR_LIMIT:
		name_label.label_settings.font_size = maxi(STANDARD_FONT_SIZE - ((name_label.text.length() + 1) - STANDARD_CHAR_LIMIT), MIN_FONT_SIZE)
	else:
		name_label.label_settings.font_size = STANDARD_FONT_SIZE
	icon.set_texture(item.icon)
	icon.material = item.icon_material
	name_label.label_settings.font_color = item.shop_category_color.lightened(0.25)

func update_price() -> void:
	%StarCountLabel.set_text('x%d' % price)

func icon_hover() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	scale_tween = create_tween()
	scale_tween.tween_property(%IconScale, 'scale', SCALE_UP, 0.1)
	scale_tween.finished.connect(scale_tween.kill)
	AudioManager.play_sound(sfx_hover)
	Util.do_item_hover(item)

func icon_unhover() -> void:
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	scale_tween = create_tween()
	scale_tween.tween_property(%IconScale, 'scale', Vector2.ONE, 0.1)
	scale_tween.finished.connect(scale_tween.kill)
	HoverManager.stop_hover()

func icon_clicked() -> void:
	s_icon_clicked.emit()
	AudioManager.play_sound(sfx_click)

func icon_gui_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			icon_clicked()
