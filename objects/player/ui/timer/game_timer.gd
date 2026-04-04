extends Control
class_name RunTimer

@onready var label := $Label
@onready var seed_label: Label = %SeedLabel
@onready var seed_button: Button = %SeedButton

var time := 0.0
var current_minute := 0
var current_second := 0

signal s_minute_passed


func _ready() -> void:
	if SaveFileService.settings_file.show_timer:
		show()
	else:
		hide()
	if SaveFileService.run_file:
		time = SaveFileService.run_file.game_time
	current_minute = get_current_minute()
	label.set_text(get_time_string(time))
	seed_label.set_text("Seed: %s" % [RNG._str_seed if RNG._str_seed else str(RNG.base_seed)])
	seed_label.visible = RNG.is_custom_seed

func _process(delta: float) -> void:
	if not Util.get_player().game_timer_tick:
		return

	time += delta
	label.set_text(get_time_string(time))
	if not current_minute == get_current_minute():
		current_minute = get_current_minute()
		s_minute_passed.emit()
	if not current_second == floori(time):
		current_second = floori(time)
		ScoreTally.modify_score(ScoreTally.ChannelTimeBonus, -1)

static func get_time_string(timef: float) -> String:
	var time_string := "%s:%s:%s"
	
	var seconds: int = roundi(timef)
	
	var hours := floori(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floori(seconds / 60)
	seconds -= minutes * 60
	
	time_string = time_string % [get_formatted_time(hours), get_formatted_time(minutes), get_formatted_time(seconds)]
	
	return time_string

static func get_formatted_time(_time: int) -> String:
	var time_str := str(_time)
	if time_str.length() == 1:
		time_str = time_str.insert(0, "0")
	
	return time_str

func become_full_visible() -> void:
	label.self_modulate = Color.WHITE
	label.label_settings.font_color = Color.LIGHT_GREEN
	label.scale = Vector2.ONE * 1.25
	# Seed stuff
	if not RNG.is_custom_seed:
		seed_label.modulate = Color.TRANSPARENT
	seed_button.mouse_entered.connect(_hover_seed_label)
	seed_button.mouse_exited.connect(_stop_hover_seed_label)
	seed_button.pressed.connect(_seed_label_clicked)
	await get_tree().process_frame
	seed_button.size = seed_label.size
	seed_label.show()
	_make_seed_visible()

func get_current_minute() -> int:
	var seconds: int = roundi(time)
	var hours := floori(seconds / 3600)
	seconds -= hours * 3600
	var minutes := floori(seconds / 60)
	return minutes

func set_timer_color(color: Color) -> void:
	label.label_settings.font_color = color

#region Seed

var _seed_ival: ActiveInterval

func _make_seed_visible() -> void:
	_seed_ival = LerpProperty.setup(seed_label, ^"modulate", 0.2, Color.WHITE).interp(Tween.EASE_IN, Tween.TRANS_QUAD).start(self, true)

func _hover_seed_label() -> void:
	HoverManager.hover("Click to copy seed")
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color(0.4, 1, 1, 1)).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _stop_hover_seed_label() -> void:
	HoverManager.stop_hover()
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.15, Color.WHITE).interp(Tween.EASE_OUT, Tween.TRANS_QUAD).start(self)

func _seed_label_clicked() -> void:
	DisplayServer.clipboard_set(RNG._str_seed)
	HoverManager.hover("Seed copied!")
	AudioManager.play_sound(load("res://audio/sfx/ui/GUI_balloon_popup.ogg"), 10.0)
	seed_label.self_modulate = Color.ORANGE
	_seed_ival = LerpProperty.setup(seed_label, ^"self_modulate", 0.6, Color(0.4, 1, 1, 1)).start(self)

#endregion
