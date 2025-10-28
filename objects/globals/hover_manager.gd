@tool
extends CanvasLayer

const YAdjust := (99.0 / 121.0)

@export_multiline var text := '':
	set(x):
		if not label: return
		set_text(x)
	get:
		if not label: return ''
		return label.text

# Child references
@onready var label: RichTextLabel = %Text
@onready var bubble := %Bubble
@onready var text_pos: Control = %TextPos
@onready var hover_root: Control = %HoverRoot

var curr_values: Array = [16, 0.025]

# Locals
var plain_text: String:
	get:
		var regex := RegEx.new()
		regex.compile("\\[.*?\\]")
		var text_without_tags = regex.sub(text, "", true)
		return text_without_tags

func _ready() -> void:
	hover_root.hide()
	process_mode = PROCESS_MODE_ALWAYS
	if Engine.is_editor_hint():
		set_process(false)
		hide()
	else:
		show()

func set_text(string: String):
	if string == '':
		label.set_text(string)
		return

	# Set the label's text
	label.set_text(string)

	# Calculate the bubble scale based on string size
	var font_size: int = curr_values[0]
	var label_size := label.size
	label.add_theme_font_size_override("normal_font_size", font_size)
	var font: Font = label.get_theme_font('normal_font')
	var text_size := font.get_multiline_string_size(plain_text, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, font_size)
	if curr_values[2]:
		# If title: Take the highest X scale between the two
		@warning_ignore("narrowing_conversion")
		var title_text_size := font.get_multiline_string_size(curr_values[2], HORIZONTAL_ALIGNMENT_LEFT, label_size.x, font_size * 1.2)
		text_size.x = max(text_size.x, title_text_size.x)
	
	bubble.scale = Vector2(clampf((text_size.x * 0.002) + curr_values[1], 0.001, 0.65), max(0.2, label.get_line_count() * 0.14) * (float(font_size) / 20.0))
	bubble.position.y = -242 + ((label.get_line_count() - 1) * bubble.scale.y * 25.0)

	text_pos.position.x = 32 - (bubble.scale.x * 20.0)
	label.global_position = text_pos.global_position
	if label.get_line_count() == 1:
		label.position.y += (2.5 * (float(font_size) / 20.0))

	if curr_values[2]:
		# If title: Increase label position slightly to account for title size
		label.position.y -= ((font_size * 1.2) - font_size)

func _process(_delta: float) -> void:
	if hover_root.visible:
		# Find bounds of viewport
		var viewport_rect: Rect2 = hover_root.get_viewport_rect()
		var mouse_pos: Vector2 = hover_root.get_global_mouse_position()
		# Set initial bubble position
		hover_root.global_position = mouse_pos
		# Find bounds of bubble
		var global_rect: Rect2 = bubble.get_global_rect()
		# Compare bubble bounds to the viewport bounds
		var adjusted_x_pos: float = hover_root.global_position.x + global_rect.size.x

		var _y_pos: float = hover_root.global_position.y
		if label.get_line_count() > 2:
			_y_pos -= (14 * (label.get_line_count() - 2))
			hover_root.global_position.y = _y_pos

		# Adjust x position if bubble bounds go out of viewport bounds
		if adjusted_x_pos > viewport_rect.size.x:
			hover_root.global_position.x -= (adjusted_x_pos - viewport_rect.size.x)

		# Adjust y position if bubble bounds go out of viewport bounds
		var adjusted_y_pos: float = _y_pos + (global_rect.size.y * YAdjust)

		if adjusted_y_pos > viewport_rect.size.y:
			hover_root.global_position.y -= (adjusted_y_pos - viewport_rect.size.y)

func hover(_text: String, font_size := 18, extra_x_margin := 0.025, title := "", title_color := Color.BLACK) -> void:
	if Engine.is_editor_hint():
		return
	curr_values = [font_size, extra_x_margin, title, title_color]
	if title:
		text = "[color=%s][font_size=%s]%s[/font_size][/color]\n%s" % [title_color.to_html(), font_size * 1.2, title, _text]
	else:
		text = _text
	hover_root.show()

func stop_hover() -> void:
	if Engine.is_editor_hint():
		return
	hover_root.hide()
