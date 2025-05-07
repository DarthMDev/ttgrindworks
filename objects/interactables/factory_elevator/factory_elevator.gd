extends AnimatableBody3D
class_name FactoryElevator

enum ElevatorMode {
	DETECTION,
	TIMER
}
@export var mode := ElevatorMode.DETECTION

@export var final_y := 0.0
@export var initial_y := 0.0
@export var rise_time := 3.0
@export var pause_time := 5.0

@onready var sfx_player : AudioStreamPlayer3D = $SFXPlayer
@onready var timer : Timer = %ElevatorTimer

var can_rise := true
var rise_tween : Tween

## 1 = at top -1 means at bottom
var trip_part := -1


signal s_activated
signal s_destination_reached


func _ready() -> void:
	timer.wait_time = pause_time

func body_entered(body : Node3D) -> void:
	if body is Player and can_rise:
		can_rise = false
		rise()

func is_rising() -> bool:
	if rise_tween:
		return rise_tween.is_valid() and rise_tween.is_running()
	return false


func rise(to := final_y, time := rise_time) -> void:
	if rise_tween and rise_tween.is_running():
		rise_tween.kill()
	
	trip_part = -trip_part
	
	rise_tween = create_tween()
	rise_tween.tween_callback(sfx_player.play)
	rise_tween.set_trans(Tween.TRANS_QUAD)
	rise_tween.tween_property(self, 'position', Vector3(position.x, to, position.z), time)
	rise_tween.finished.connect(
	func():
		rise_tween.kill()
		sfx_player.stop()
	)
	rise_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	rise_tween.finished.connect(timer.start)

func timer_timeout() -> void:
	if mode == ElevatorMode.TIMER:
		match trip_part:
			1: rise(final_y)
			-1: rise(initial_y)
