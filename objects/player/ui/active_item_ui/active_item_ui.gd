@tool
extends Control

const CATEGORY_COLORS : Dictionary[ItemActive.ActiveType, Color] = {
	ItemActive.ActiveType.REALTIME : Color('00cc60'),
	ItemActive.ActiveType.BATTLE : Color('38a6ff'),
	ItemActive.ActiveType.WHENEVER : Color('cf72e9'),
	ItemActive.ActiveType.ANY : Color("fd1975")
}

const BASE_MARGIN := 0.4
const TICK := preload("res://objects/player/ui/active_item_ui/meter_tick.tscn")


@export var item : ItemActive:
	set(x):
		if item and not Engine.is_editor_hint():
			disconnect_current_item()
		item = x
		if item:
			if not Engine.is_editor_hint():
				item.s_current_charge_changed.connect(set_value)
			setup_item(x)
			show()
		else:
			clear_item()

@onready var progress_circle : TextureProgressBar = %ProgressBar
@onready var item_icon : TextureRect = %ItemIcon
@onready var tick_origin : Control = %TickOrigin
@onready var fail_sound_sfx : AudioStreamPlayer = %FailSoundSFX
@onready var denycon : TextureRect = %Denycon

signal s_use_pressed


func _ready() -> void:
	if Engine.is_editor_hint(): return
	SaveFileService.s_settings_changed.connect(on_settings_changed)
	on_settings_changed()

func setup_item(new_item : ItemActive) -> void:
	if new_item.icon:
		item_icon.set_texture(new_item.icon)
	else:
		printerr("ERR: Active item %s has no icon to display!" % new_item.item_name)
	
	progress_circle.max_value = new_item.charge_count
	progress_circle.value = new_item.current_charge
	set_ticks(new_item.charge_count)
	do_charge_tween(progress_circle.value)
	update_color()
	if new_item.node:
		new_item.node.s_use_failed.connect(on_use_failed)

func clear_item() -> void:
	hide()
	clear_ticks()
	progress_circle.value = 0
	item_icon.set_texture(null)

func set_value(value : int) -> void:
	if not item or not is_instance_valid(progress_circle):
		return
	do_charge_tween(value)

var charge_tween : Tween
func do_charge_tween(value : float) -> void:
	if charge_tween and charge_tween.is_running():
		charge_tween.kill()
	
	var time := 1.0
	if is_equal_approx(0.0, value):
		time = item.custom_discharge_time
	charge_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	charge_tween.tween_property(progress_circle, 'value', value, time)
	charge_tween.finished.connect(charge_tween.kill)

func set_ticks(ticks : int) -> void:
	clear_ticks()
	progress_circle.max_value = ticks
	if ticks < 2:
		return
	
	var unit := 360 / ticks 
	for i in ticks:
		var tick := TICK.instantiate()
		tick_origin.add_child(tick)
		tick.rotation_degrees = unit * i

func clear_ticks() -> void:
	for child in tick_origin.get_children():
		child.queue_free()

func disconnect_current_item() -> void:
	if item and item.s_current_charge_changed.is_connected(set_value):
		item.s_current_charge_changed.disconnect(set_value)

func _process(_delta : float) -> void:
	if Engine.is_editor_hint(): return
	
	if Input.is_action_just_pressed('use_pocket_prank'):
		s_use_pressed.emit()
	
	%KeyInput.set_visible(get_button_prompt_visible())

var fail_tween : Tween
func on_use_failed() -> void:
	if fail_tween and fail_tween.is_running():
		fail_tween.kill()
	denycon.self_modulate.a = 0.0
	
	fail_tween = create_tween()
	fail_tween.tween_callback(fail_sound_sfx.set_pitch_scale.bind(RandomService.randf_range_channel('true_random', 0.7, 1.8)))
	fail_tween.tween_callback(fail_sound_sfx.play)
	fail_tween.tween_property(denycon, 'self_modulate:a', 1.0, 0.25)
	fail_tween.tween_property(denycon, 'self_modulate:a', 0.0, 0.25)
	fail_tween.finished.connect(fail_tween.kill)

func update_color() -> void:
	if item:
		progress_circle.tint_progress = CATEGORY_COLORS[item.active_type]

func on_settings_changed() -> void:
	sync_button_prompt()

func sync_button_prompt() -> void:
	var size_per_char := 3
	var key_label: Label = %KeyLabel
	var new_text := input_to_text(InputMap.action_get_events('use_pocket_prank')[1])
	var test = InputMap.action_get_events('use_pocket_prank')
	key_label.set_text(new_text)
	key_label.label_settings.font_size = 24 - ((key_label.text.length() * size_per_char) - size_per_char)
	%KeyInput.set_visible(get_button_prompt_visible())

func input_to_text(input : InputEvent) -> String:
	if not input: 
		return "<UNBOUND>"
	var text := input.as_text()
	if text.begins_with("Joypad"):
		return "Q"
	elif text.ends_with(" (Physical)"):
		return text.trim_suffix(" (Physical)")
	return input.as_text()

func get_button_prompt_visible() -> bool:
	if not SaveFileService.settings_file.button_prompts:
		return false
	if item:
		return item.charge_count == item.current_charge and item.node.check_player_state()
	return false
