extends Node3D

@export var delete_time := 2.0

@onready var timer: Timer = %DeleteTimer

func _ready() -> void:
	if delete_time <= 0.0 :
		return
	
	timer.wait_time = delete_time
	timer.start()

func on_timer_timeout() -> void:
	queue_free()
