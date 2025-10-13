extends Control


const COLOR_INACTIVE := Color('ff0000')
const COLOR_ACTIVE := Color('fdb100')
const COLOR_NEED := Color('ff0000') #Color.GREEN (feature in consideration)
const LEEWAY_RANGE := 10.0
const GOAL_SHIFT_AMOUNT := 5.0
const GOAL_BOUNDS := Vector2(40.0, 60.0)
const BASE_BUMP_QUOTA := 4

## Child References
@onready var progress_bar : ProgressBar = $Game/ProgressBar
@onready var goal_bar : Panel = $Game/ProgressBar/GoalBar
@onready var arrow_left : TextureRect = $Game/Arrows/ArrowLeft
@onready var arrow_right : TextureRect = $Game/Arrows/ArrowRight

## Locals
var value := 0.0:
	set(x):
		if is_instance_valid(progress_bar):
			progress_bar.value = x
			value = progress_bar.value
var goal := 50.0
## False means left needs pressed, true means right needs pressed
var arrow_needed := false
var loss_bump := -4.0
var gain_bump := 8.0
var bump_quota := BASE_BUMP_QUOTA


func _process(_delta : float) -> void:
	assess_input()

func set_goal(new_goal : float) -> void:
	goal = clamp(new_goal, GOAL_BOUNDS.x, GOAL_BOUNDS.y)
	goal_bar.position.y = progress_bar.size.y - (progress_bar.size.y * (new_goal / progress_bar.max_value))

func assess_input() -> void:
	color_arrows()
	
	match arrow_needed:
		false:
			if Input.is_action_just_pressed('move_left'):
				input_success()
		_:
			if Input.is_action_just_pressed('move_right'):
				input_success()

func input_success() -> void:
	arrow_needed = not arrow_needed
	bump_quota -= 1
	if bump_quota <= 0:
		value += gain_bump
		bump_quota = BASE_BUMP_QUOTA

func bump_down() -> void:
	value += loss_bump

func is_winning() -> bool:
	return abs(goal - value) < LEEWAY_RANGE

func shift_goal() -> void:
	set_goal(goal + [GOAL_SHIFT_AMOUNT, -GOAL_SHIFT_AMOUNT][randi() % 2])

func color_arrows() -> void:
	if Input.is_action_pressed('move_left'):
		arrow_left.modulate = COLOR_ACTIVE
	else:
		if not arrow_needed:
			arrow_left.modulate = COLOR_NEED
		else:
			arrow_left.modulate = COLOR_INACTIVE
	if Input.is_action_pressed('move_right'):
		arrow_right.modulate = COLOR_ACTIVE
	else:
		if arrow_needed:
			arrow_right.modulate = COLOR_NEED
		else:
			arrow_right.modulate = COLOR_INACTIVE
