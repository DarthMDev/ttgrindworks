@tool
extends Control3D
class_name SpeechBubble

const MAX_DIST := 40.0

@export_multiline var text := '':
	set(x):
		if not label: return
		set_text(x)
	get:
		if not label: return ''
		return label.text

@export var auto_expire := true
@export var hide_with_distance := true

# Child references
@onready var label: RichTextLabel = $Text
@onready var bubble := $Bubble
@onready var text_pos: Control = %TextPos

# Locals
var plain_text: String:
	get:
		var regex := RegEx.new()
		regex.compile("\\[.*?\\]")
		var text_without_tags = regex.sub(text, "", true)
		return text_without_tags

# Signals
signal finished

func set_text(string: String):
	if string == '':
		label.set_text(string)
		return
	var height_mod := 1.0
	var text_y_mod := 1.0

	# Strings starting with . should be thought bubbles
	if string[0] == '.' and not string.begins_with('...'):
		bubble.texture = load("res://ui_assets/misc/chatbox-thought.png")
		string = string.trim_prefix('.')
		height_mod = 1.6
		text_y_mod = height_mod / 1.75
	elif Engine.is_editor_hint():
		bubble.texture = load("res://ui_assets/misc/chatbox2.png")

	# Set the label's text
	label.set_text(string)

	# Calculate the bubble scale based on string size
	var label_size := label.size
	var font: Font = label.get_theme_font('normal_font')
	var text_size := font.get_multiline_string_size(plain_text, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 20)
	bubble.scale = Vector2(clampf((text_size.x * 0.002) + 0.025, 0.1, 0.65), max(0.2, (label.get_line_count() * 0.14) * height_mod))

	text_pos.position.x = 32 - (bubble.scale.x * 20.0)
	label.global_position = text_pos.global_position
	if label.get_line_count() == 1:
		label.position.y += 2.5
	label.position.y *= text_y_mod

	# No need to free self if in editor, so...
	if Engine.is_editor_hint():
		return

	# Create a local timer to wait out before freeing
	await Task.delay(2.0 + (string.length() * 0.1))
	finished.emit()

func set_font(font: Font):
	if not label:
		await Util.s_process_frame
	label.add_theme_font_override('normal_font', font)
	set_text(text)

func done(): 
	if auto_expire:
		queue_free()

func _update():
	if Engine.is_editor_hint():
		return
	super()
	
	## Hide based on max camera distance
	if hide_with_distance:
		var camera := get_viewport().get_camera_3d()
		var target_position: Vector3 = target.get_global_transform_interpolated().origin
		var cam_dist: float = camera.global_position.distance_to(target_position)
		force_hide = cam_dist >= MAX_DIST
