@tool
extends Area3D
class_name PushableComponent

const ARROW_EXTRA_HEIGHT := 0.1

@onready var remote_transform: = $RemoteTransform3D

@export var pushable: bool = true

@export_group('Pushable Directions', 'is_pushable')
@export var is_pushable_right: bool = false:
	set(new):
		is_pushable_right = new
		await NodeGlobals.until_ready(self)
		%PosXArrow.visible = is_pushable_right
		
@export var is_pushable_left: bool = false:
	set(new):
		is_pushable_left = new
		await NodeGlobals.until_ready(self)
		%NegXArrow.visible = is_pushable_left
		
@export var is_pushable_forward: bool = false:
	set(new):
		is_pushable_forward = new
		await NodeGlobals.until_ready(self)
		%PosZArrow.visible = is_pushable_forward
		
@export var is_pushable_backward: bool = false:
	set(new):
		is_pushable_backward = new
		await NodeGlobals.until_ready(self)
		%NegZArrow.visible = is_pushable_backward

var push_position: Vector3
var push_direction: Vector3
var face_direction: float

signal pushing

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		child_entered_tree.connect(_set_debug_arrow_height)
		child_exiting_tree.connect(_set_debug_arrow_height)
		_set_debug_arrow_height()
	else:
		$DebugArrows.hide()
		body_entered.connect(_on_body_entered)
		pushing.connect(_on_pushing)
	
func _set_debug_arrow_height(_node = null):
	var bounds := NodeGlobals.calculate_spatial_bounds(self, false, [$DebugArrows])
	$DebugArrows.position.y = bounds.end.y + 0.1

func _on_body_entered(body: Node3D):
	if pushable and body is Player:
		var collision: KinematicCollision3D = body.get_last_slide_collision()
		if collision:
			push_position = collision.get_position()
			push_direction = collision.get_normal().normalized()
			face_direction = collision.get_angle(0, Vector3.FORWARD) * -1
			if push_direction == Vector3.BACK and is_pushable_backward:
				pushing.emit()
			elif push_direction == Vector3.FORWARD and is_pushable_forward:
				pushing.emit()
			elif push_direction == Vector3.LEFT and is_pushable_left:
				pushing.emit()
			elif push_direction == Vector3.RIGHT and is_pushable_right:
				pushing.emit()

func _on_pushing():
	var player := Util.get_player()
	if not player or not player.controller.current_state.accepts_interaction():
		return
	
	var bounds := NodeGlobals.calculate_spatial_bounds(self, false, [$DebugArrows])
	remote_transform.global_position = push_position + (push_direction * 0.5)
	remote_transform.position.y = bounds.position.y
	# We set rotation in Player's push state bc the child "Toon" node rotates,
	# not the base player
	player.start_pushing(self)
	
func assign_player(player: Player):
	remote_transform.remote_path = player.get_path()
	
func clear_player():
	remote_transform.remote_path = ^''

func do_push(amount: float):
	owner.position += -push_direction * amount
