extends Control

## Constants
const SFX_ALERT := preload('res://audio/sfx/objects/goon/CHQ_GOON_tractor_beam_alarmed.ogg')
const SFX_GOOD := preload('res://audio/sfx/battle/gags/toonup/sparkly.ogg')
const SFX_NEUTRAL := preload('res://audio/sfx/misc/MG_sfx_travel_game_no_bonus.ogg')
const SFX_BAD := preload('res://audio/sfx/battle/gags/drop/AA_drop_bigweight_miss.ogg')
const SFX_IDK := preload("res://audio/sfx/misc/MG_maze_pickup.ogg")
const SFX_LEAVE := preload("res://audio/sfx/objects/spotlight/LB_laser_beam_off_2.ogg")
const RANDOM_CHARS := "?ABCDEFHIJLMOPQRSTUVWXYZ123456780      "


## Config
@export var anomaly_label_settings : LabelSettings
@export var anomalies : Array[FloorModifier]

## Child References
@onready var title := $TitleAnchor
@onready var anomaly_container := $AnomalyContainer
@onready var anomaly_sizer := $AnomalySizer

## Locals
var tween : Tween


func play() -> void:
	if tween:
		tween.kill()
	
	populate_anomalies()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	# Show alert
	tween.tween_callback(AudioManager.play_snippet.bind(SFX_ALERT,0.0,2.0))
	tween.tween_property(title,'scale',Vector2(1,1),1.0)
	tween.tween_interval(1.0)
	
	# Show Anomalies
	for i in anomaly_container.get_child_count():
		anomaly_container.get_child(i).show()
		tween.tween_callback(AudioManager.play_sound.bind(get_sfx(anomalies[i].get_mod_quality())))
		var scaler := anomaly_container.get_child(i).get_node('AnomalyScaler')
		tween.tween_property(scaler,'scale',Vector2(1,1),1.0)
	tween.tween_interval(1.0)
	
	# Shrink labels away
	tween.tween_callback(AudioManager.play_sound.bind(SFX_LEAVE))
	tween.set_parallel(true)
	var speed := 1.0
	for i in range(anomaly_container.get_child_count() - 1, -1, -1):
		var scaler := anomaly_container.get_child(i).get_node('AnomalyScaler')
		tween.tween_property(scaler,'scale',Vector2(0.01,0.01),speed)
		speed += 0.1
	tween.tween_property(title,'scale',Vector2(0.01,0.01),speed)
	
	tween.finished.connect(func(): queue_free())

func populate_anomalies() -> void:
	for anomaly in anomalies:
		var label := Label.new()
		var sizer := anomaly_sizer.duplicate()
		anomaly_container.add_child(sizer)
		sizer.get_node('AnomalyScaler').add_child(label)
		label.label_settings = anomaly_label_settings.duplicate()
		if not is_obscured():
			label.set_text("- " + anomaly.get_mod_name())
		else:
			label.set_text("- ")
			for i in RandomService.randi_range_channel('true_random', 5, 20):
				label.text += RANDOM_CHARS[RandomService.randi_channel('true_random') % RANDOM_CHARS.length()]
		color_label(label,anomaly)
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER,Control.PRESET_MODE_KEEP_SIZE)

func tween_finished_editor() -> void:
	title.scale = Vector2(0.01,0.01)
	
	for child in anomaly_container.get_children():
		child.queue_free()

func get_sfx(mod_type : FloorModifier.ModType) -> AudioStream:
	if is_obscured():
		return SFX_IDK
	match mod_type:
		FloorModifier.ModType.POSITIVE:
			return SFX_GOOD
		FloorModifier.ModType.NEUTRAL:
			return SFX_NEUTRAL
		_:
			return SFX_BAD

func color_label(label : Label, anomaly : FloorModifier) -> void:
	if is_obscured():
		label.label_settings.font_color = Color.DIM_GRAY
		label.label_settings.shadow_color = Color.BLACK
	else:
		label.label_settings.font_color = anomaly.text_color
		label.label_settings.shadow_color = anomaly.outline_color

func is_obscured() -> bool:
	if not is_instance_valid(Util.get_player()):
		return false
	return Util.get_player().obscured_anomalies and not Util.get_player().see_descriptions
