extends Node3D

signal s_stomped(obj: Node3D, the_stomper_in_question: Node3D)

const BOUNDS := 25

@export var speed: float = 1.0

func _ready() -> void:
	%Coll.area_entered.connect(try_stomp)

func is_button() -> bool:
	return false

func _physics_process(delta: float) -> void:
	position.x += speed * delta
	if position.x > BOUNDS or position.x < -BOUNDS:
		queue_free()

func try_stomp(area: Area3D) -> void:
	if area.name == "ObjectDetection":
		s_stomped.emit(self, area.get_parent().get_parent())
		queue_free()
