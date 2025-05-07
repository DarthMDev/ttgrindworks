@tool
extends Node3D


const OUTER_PARAMETERS : Dictionary[bool, Dictionary] = {
	true : {
		"fire_panning_speed" : Vector2(0.5, 2.0),
		"FirePanningVisibility" : 1.0,
		"AddFresnelVisibility" : 3.59
	},
	false : {
		"fire_panning_speed" : Vector2(0.0, 2.935),
		"FirePanningVisibility" : 5.0,
		"AddFresnelVisibility" : 10.0
	}
}
const INNER_PARAMETERS : Dictionary[bool, Dictionary] = {
	true : {
		"Fresnel_visibility" : 2.0,
		"Flame_Visibility" : 1.0,
	},
	false : {
		"Fresnel_visibility" : 0.3,
		"Flame_Visibility" : 0.7,
	},
}

const RETRACT_SIZE := Vector3(0.1, 0.1, 0.1)
const TWEEN_LENGTH := 0.2

@export var enabled := false:
	set(x):
		enabled = x
		if not is_node_ready():
			await ready
		
		if x: turn_on()
		else: turn_off()

@export var flame_length := 1.0:
	set(x):
		flame_length = x
		if not is_node_ready():
			await ready
		if enabled and (not transition_tween or not transition_tween.is_running()):
			flame.scale.z = x

@export var automatic := true:
	set(x):
		automatic = x
		if not is_node_ready():
			return
		if x and not automatic_active:
			start_timer()
@export var down_time := 3.0
@export var up_time := 2.0
@export var delay_time := 0.0
@export var base_damage := -5
@export var start_enabled := false

@onready var flame : Node3D = %Flame
@onready var inner_flame : MeshInstance3D = %FlameInner
@onready var outer_flame : MeshInstance3D = %FlameOuter
@onready var timer : Timer = %Timer

var transition_tween : Tween
var inner_mat : ShaderMaterial:
	get: return inner_flame.get_surface_override_material(0)
var outer_mat : ShaderMaterial:
	get: return outer_flame.get_surface_override_material(0)
var automatic_active := false


func _ready() -> void:
	if automatic:
		enabled = start_enabled
		start_timer()

func start_timer() -> void:
	automatic_active = true
	
	if not is_equal_approx(delay_time, 0.0):
		timer.wait_time = delay_time
		timer.start()
		await timer.timeout
	
	while true:
		if not automatic:
			automatic_active = false
			return
		
		if enabled: timer.wait_time = down_time
		else: timer.wait_time = up_time
		
		enabled = not enabled
		timer.start()
		await timer.timeout

func turn_on() -> void:
	if transition_tween and transition_tween.is_running():
		transition_tween.kill()
	
	transition_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	transition_tween.tween_property(flame, 'scale', Vector3(1.0, 1.0, flame_length), TWEEN_LENGTH)
	transition_tween.tween_property(%burning_sfx, "pitch_scale", 1.0, TWEEN_LENGTH)
	transition_tween.tween_property(%burning_sfx, "volume_db", -7, TWEEN_LENGTH)
	append_parameter_changes(transition_tween)
	%PlayerDetection.set_deferred('monitoring', true)


func turn_off() -> void:
	if transition_tween and transition_tween.is_running():
		transition_tween.kill()
	
	transition_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	transition_tween.tween_property(flame, 'scale', RETRACT_SIZE, TWEEN_LENGTH)
	transition_tween.tween_property(%burning_sfx, "pitch_scale", 0.5, TWEEN_LENGTH)
	transition_tween.tween_property(%burning_sfx, "volume_db", -14, TWEEN_LENGTH)
	append_parameter_changes(transition_tween)
	%PlayerDetection.set_deferred('monitoring', false)

func append_parameter_changes(tween : Tween) -> void:
	var inner_params : Dictionary = INNER_PARAMETERS.get(enabled)
	var outer_params : Dictionary = OUTER_PARAMETERS.get(enabled)
	
	for parameter in inner_params.keys():
		tween.tween_method(
			func(x): inner_mat.set_shader_parameter(parameter, x)
		,inner_mat.get_shader_parameter(parameter), inner_params[parameter], TWEEN_LENGTH)
	
	for parameter in outer_params.keys():
		tween.tween_method(
			func(x): outer_mat.set_shader_parameter(parameter, x)
		,outer_mat.get_shader_parameter(parameter), outer_params[parameter], TWEEN_LENGTH)

func on_body_entered(body : Node3D) -> void:
	if body is Player:
		hurt_player(body)

func hurt_player(player : Player) -> void:
	player.quick_heal(Util.get_hazard_damage(base_damage))
	AudioManager.play_sound(player.toon.yelp)
