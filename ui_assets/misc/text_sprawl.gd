@tool
extends Label


@export var pause_time := 0.25
@export var fadeout_time := 2.0
@export var sfx: Array[AudioStream] = []
@export var autoplay := true
@export_tool_button("Play") var play_button = do_sprawl


var sprawl_tween: Tween


func _ready() -> void:
	if autoplay:
		do_sprawl()
	else:
		hide()

func do_sprawl(txt: String = text) -> Tween:
	if sprawl_tween and sprawl_tween.is_running():
		sprawl_tween.kill()
	
	visible_characters = 0
	text = txt
	show()
	sprawl_tween = create_tween()
	for i in get_total_character_count():
		append_text_action(sprawl_tween)
		sprawl_tween.tween_interval(pause_time)
	
	
	sprawl_tween.tween_interval(fadeout_time)
	sprawl_tween.tween_property(self, 'self_modulate:a', 0.0, fadeout_time)
	sprawl_tween.finished.connect(on_sprawl_end)
	return sprawl_tween

func append_text_action(tween: Tween) -> void:
	tween.tween_callback(add_visible_character)
	if not sfx.is_empty() and not Engine.is_editor_hint():
		tween.tween_callback(AudioManager.play_sound.bind(sfx.pick_random()))

func add_visible_character() -> void:
	visible_characters += 1

func on_sprawl_end() -> void:
	sprawl_tween.kill()
	if not Engine.is_editor_hint():
		queue_free()
	else:
		self_modulate.a = 1.0
