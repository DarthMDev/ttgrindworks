extends Control
class_name RunTimer

@onready var label := $Label

var time := 0.0

func _ready() -> void:
	if SaveFileService.settings_file.show_timer:
		show()
	else:
		hide()

func _process(delta: float) -> void:
	if not Util.get_player().game_timer_tick:
		return

	time += delta
	label.set_text(get_time_string(time))

static func get_time_string(timef : float) -> String:
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
