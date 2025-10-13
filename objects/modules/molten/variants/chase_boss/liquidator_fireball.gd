extends Area3D


const FIREBALL_SIZE := Vector3.ONE * 2.5

var damage := -4
var velocity := Vector3.ZERO


func _ready() -> void:
	var grow_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	grow_tween.tween_property($Meteor, 'scale', FIREBALL_SIZE, 0.25)

func explode() -> void:
	pass

func _on_body_entered(body):
	if body is Player:
		body.quick_heal(Util.get_hazard_damage(damage))

func _physics_process(delta: float) -> void:
	var prev_position: Vector3 = global_position
	global_position += velocity * delta
	
	# Make fireball face moving direction
	if not global_position.is_equal_approx(prev_position):
		$Meteor.look_at(prev_position)
		$Meteor.rotation_degrees.y += 180.0

func lifetime_over() -> void:
	queue_free()
