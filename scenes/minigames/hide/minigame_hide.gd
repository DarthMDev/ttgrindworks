extends MiniGame
class_name MiniGameHide

## Game State
enum GameState {
	INACTIVE,
	ACTIVE
}
var state := GameState.INACTIVE:
	set(x):
		state = x
		refresh_state()

const SPOT_SEPARATION := 3.5 # Distance between hiding spots
const LIFT_AMOUNT := 0.5 # Amount each spot lifts when hovered w/ mouse
const FULL_LIFT := 2.0 # Amount to lift a spot for the Toon to run under
const LIFT_SPEED := 4.0

## Hiding spot generation values
@onready var toon : Toon = $World3D/Toon
@onready var hover_selector : Control = $HoverSelector
@onready var hiding_spot_origin : Node3D = $World3D/HidingSpots
@onready var hiding_spot_objects : Array[Node]:
	get: return $HidingSpotObjects.get_children()
@onready var door : CogDoor = $World3D/CogDoor

## Local game values
var spots_needed := 4
var whiff_chance := 0 # Chance 0-100 for Cog to guarantee a wrong guess
var doomed_chance := 0 # Chance 0-100 for Co to guarantee a right guess
var selected_spot : Node3D
var hovered_spot : Node3D


func _initialize() -> void:
	apply_difficulty()
	place_hiding_spots()

func start_game() -> void:
	state = GameState.ACTIVE

func apply_difficulty() -> void:
	match difficulty:
		0:
			whiff_chance = 25
		2:
			spots_needed = 3
			whiff_chance = 10
		3:
			spots_needed = 3
		4:
			spots_needed = 2
		5:
			spots_needed = 2
			doomed_chance = 25

func place_hiding_spots() -> void:
	var x_dist := -(float(spots_needed) * SPOT_SEPARATION) / 2.0
	if spots_needed % 2 == 0: x_dist += SPOT_SEPARATION / 2.0
	for i in spots_needed:
		var new_spot : Node3D = hiding_spot_objects[RNG.channel(RNG.ChannelMinigames).randi() % hiding_spot_objects.size()]
		new_spot.reparent(hiding_spot_origin)
		new_spot.position = Vector3(x_dist, 0.0, 0.0)
		x_dist += SPOT_SEPARATION
		hook_up_spot(new_spot)

func hook_up_spot(spot : Node3D) -> void:
	var mouse_detection : StaticBody3D = spot.get_node('MouseDetection')
	mouse_detection.input_event.connect(_input_on_object.bind(spot))
	mouse_detection.mouse_entered.connect(spot_hovered.bind(spot))

func spot_hovered(spot : Node3D) -> void:
	if not state == GameState.ACTIVE: return
	hovered_spot = spot
	hover_selector.reparent(spot.get_node('LabelPos'))
	hover_selector.show()
	hover_selector.get_node('Container/Label').set_text(spot.name)

func spot_selected(spot : Node3D) -> void:
	if not state == GameState.ACTIVE: return
	state = GameState.INACTIVE
	selected_spot = spot
	hovered_spot = null
	var run_pos := Vector3(spot.get_node('ToonPosition').global_position.x, 0.0, spot.get_node('ToonPosition').global_position.z)
	await toon.run_to(run_pos, 1.5).finished
	toon.rotation.y = 0.0
	selected_spot = null

func _input_on_object(_camera, event : InputEvent, _event_position, _normal, _shape_idx, node : Node3D) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			spot_selected(node)

## Object Lifting
func _process(delta : float) -> void:
	for object : Node3D in hiding_spot_origin.get_children():
		if object == hovered_spot:
			if object.position.y < LIFT_AMOUNT:
				object.position.y += LIFT_SPEED * delta
		elif object == selected_spot:
			if object.position.y < FULL_LIFT:
				object.position.y += delta * LIFT_SPEED
		else:
			if object.position.y > 0.0:
				object.position.y -= delta * LIFT_SPEED

func refresh_state() -> void:
	$GameUI/FullScreen/Label.visible = state == GameState.ACTIVE
	hover_selector.get_node('Container').visible = state == GameState.ACTIVE
