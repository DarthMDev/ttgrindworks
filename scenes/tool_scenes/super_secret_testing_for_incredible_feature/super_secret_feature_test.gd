extends Node3D

## REMEMBER TO REMOVE THIS FROM THE PROJECT BEFORE RELEASE!!!!
## THE PEOPLE CANNOT SEE THIS!!!!!
## IT IS TOO AWESOME!!!!

const TALK_RANGE := Vector2(1.33, 1.83)

@onready var animator: AnimationPlayer = $Liquidator_v1b/AnimationPlayer

var record_effect: AudioEffectRecord
var analyzer: AudioEffectSpectrumAnalyzer


func _ready() -> void:
	# Set up our mic analyzer
	record_effect = AudioEffectRecord.new()
	analyzer = AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus(0)
	AudioServer.add_bus_effect(0, record_effect)
	AudioServer.add_bus_effect(0, analyzer)
	AudioServer.set_bus_mute(0, true)
	$AudioStreamPlayer.bus = AudioServer.get_bus_name(0)
	$AudioStreamPlayer.play()
	
	# Start recording
	record_effect.set_recording_active(true)
	
	# Set our animation
	animator.play('Death')


func _process(_delta: float) -> void:
	# I'm not really sure how to comprehend what is actually being measured here
	# Thankfully, this being a secret and all, no one will know
	var analyzer_instance: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(0, 2)
	var test := analyzer_instance.get_magnitude_for_frequency_range(-1000.0, 1000.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
	var freq := test.x * 100.0
	
	var speak_range := TALK_RANGE.y - TALK_RANGE.x
	var goal_pos := TALK_RANGE.x + (speak_range * freq)
	var start_pos := animator.current_animation_position
	var pos := lerpf(start_pos, goal_pos, 0.1)
	animator.seek(pos, true)
	$Label/ProgressBar.value = lerpf($Label/ProgressBar.value, 1.0 - freq, 0.1)
