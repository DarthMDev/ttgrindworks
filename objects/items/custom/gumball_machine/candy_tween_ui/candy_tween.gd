@tool
extends CanvasLayer

const CANDY_START_POS := Vector3(-5, -5, 0)
const CANDY_CENTER_POS := Vector3.ZERO
const CANDY_END_POS := Vector3(5, 5, 0)
const CANDY_START_ROT := 179.0
const CANDY_CENTER_ROT := 0.0
const CANDY_END_ROT := -179.0
const TWEEN_STEP_LENGTH := 0.75


@export_tool_button("Run Tween") var run_tween = do_tween

@onready var candy : Node3D = %Candy

var tween : Tween



func do_tween() -> void:
	if tween and tween.is_running():
		tween.kill()
	candy.hide()
	candy.position = CANDY_START_POS
	candy.rotation_degrees.y = CANDY_START_ROT
	candy.show()
	
	tween = create_tween().set_trans(Tween.TRANS_CIRC)
	tween.tween_property(candy, 'position', CANDY_CENTER_POS, TWEEN_STEP_LENGTH)
	tween.parallel().tween_property(candy, 'rotation_degrees:y', CANDY_CENTER_ROT, TWEEN_STEP_LENGTH)
	tween.tween_property(candy, 'position', CANDY_END_POS, TWEEN_STEP_LENGTH)
	tween.parallel().tween_property(candy, 'rotation_degrees:y', CANDY_END_ROT, TWEEN_STEP_LENGTH)
	tween.finished.connect(tween.kill)
