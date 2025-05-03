extends Node3D

const DETECTION_CHANCE := 0.5
const WANDER_TEX := "res://ui_assets/misc/PetEmoteConfused2.png"
const CHASE_TEX := "res://ui_assets/misc/PetEmoteSurprised.png"
const CHASE_MULT := 1.2
const SFX_SURPRISE := preload('res://audio/sfx/objects/moles/Mole_Surprise.ogg')
const SFX_LAND = preload("res://audio/sfx/toon/MG_cannon_hit_dirt.ogg")

enum MoleState {
	WANDER,
	CHASE,
	STOPPED,
}
var state := MoleState.WANDER

## Local position, bounding box start for how far mole can travel
@export var bounding_start := Vector2.ZERO
## Local position, bounding box end for how far mole can travel
@export var bounding_end := Vector2.ONE

## Damage to do to the player
@export var base_damage := -5
## Movement speed
@export var speed := 1.0

## The mole...
@onready var mole : Node3D = %mole_cog

## Locals
var goal_pos := Vector3.ZERO
var reached_goal := true
var chase_node : Node3D
var can_chase := true


func _physics_process(delta: float) -> void:
	if state == MoleState.WANDER:
		wander(delta)
	elif state == MoleState.CHASE:
		chase(delta)

func wander(delta: float) -> void:
	if reached_goal:
		goal_pos = get_wander_pos()
		reached_goal = false
	
	move_toward_goal(delta)

func chase(delta : float) -> void:
	if not is_instance_valid(chase_node):
		stop_chasing()
	goal_pos = get_parent().to_local(chase_node.global_position)
	
	if not is_point_valid(goal_pos):
		stop_chasing()
		return
	
	move_toward_goal(delta * CHASE_MULT)

func move_toward_goal(delta : float) -> void:
	var next_step := position.move_toward(goal_pos, speed * delta)
	position = Vector3(next_step.x, position.y, next_step.z)
	if position.distance_to(goal_pos) < 0.1:
		reached_goal = true

func get_wander_pos() -> Vector3:
	var new_pos := Vector3.ZERO
	
	new_pos.x = RandomService.randf_range_channel('true_random', bounding_start.x, bounding_end.x)
	new_pos.z = RandomService.randf_range_channel('true_random', bounding_start.y, bounding_end.y)
	return new_pos

func body_entered_hit(body : Node3D) -> void:
	if body is Player:
		player_hit(body)

func body_entered_chase(body : Node3D) -> void:
	if body is Player:
		try_chase_player(body)

func body_exited_chase(body : Node3D) -> void:
	if body is Player:
		stop_chasing()

func player_hit(player : Player) -> void:
	if player.state == Player.PlayerState.STOPPED:
		stop_chasing()
		return
	player.set_animation('neutral')
	
	player.state = Player.PlayerState.STOPPED
	player.toon.set_emotion(Toon.Emotion.SURPRISE)
	
	%AnimationPlayer.play('dive')
	await Task.delay(0.1)
	await launch_player(player)
	stop_chasing()
	player.toon.set_emotion(Toon.Emotion.NEUTRAL)
	player.do_invincibility_frames()

func try_chase_player(player : Player) -> void:
	if RandomService.randf_channel('true_random') > DETECTION_CHANCE:
		chase_node = player
		state = MoleState.CHASE
		set_display(GameLoader.load(CHASE_TEX))
		%StateDisplay.show()

func stop_chasing() -> void:
	chase_node = null
	state = MoleState.WANDER
	goal_pos = get_wander_pos()
	set_display(GameLoader.load(WANDER_TEX))
	can_chase = false
	%ChaseCooldown.start()
	Task.delay(3.0).connect(%StateDisplay.hide)
	await %ChaseCooldown.timeout
	%StateDisplay.hide()
	can_chase = true

func is_point_valid(point : Vector3) -> bool:
	var point_test := Vector2(point.x, point.z)
	
	if point_test.x < bounding_start.x or point_test.x > bounding_end.x:
		return false
	elif point_test.y < bounding_start.y or point_test.y > bounding_end.y:
		return false
	return true

func set_display(img : Texture2D) -> void:
	%StateDisplay.set_texture(img)

func pop_out() -> void:
	var pop_tween := create_tween()
	pop_tween.tween_property(mole,'position:y', 0.0, 1.0)
	pop_tween.tween_property(mole, 'position:y', -1.25, 1.0)
	pop_tween.finished.connect(pop_tween.kill)

func launch_player(player : Player) -> void:
	player.set_animation('run')
	AudioManager.play_sound(SFX_SURPRISE)
	
	# Do launch tween
	var launch_tween := create_tween()
	launch_tween.set_trans(Tween.TRANS_EXPO)
	launch_tween.set_ease(Tween.EASE_OUT)

	var launch_y: float = player.position.y + 8.0
	var land_y: float = global_position.y

	launch_tween.tween_property(player, 'position:y', launch_y, 1.0)
	launch_tween.set_ease(Tween.EASE_IN)
	launch_tween.tween_property(player, 'global_position:y', land_y, 1.0)
	
	# Do twist tween
	var twist_tween := create_tween()
	twist_tween.tween_property(player.toon.body_node, 'rotation_degrees', player.toon.rotation_degrees + Vector3(720, 0, 720), 2.0)
	
	# Do reposition tween
	var newpos: Vector3 = get_parent().to_global(get_wander_pos())
	var reposition_tween := create_tween()
	reposition_tween.set_parallel(true)
	reposition_tween.tween_property(player, 'global_position:x', newpos.x, 2.0)
	reposition_tween.tween_property(player, 'global_position:z', newpos.z, 2.0)
	
	await launch_tween.finished
	launch_tween.kill()
	twist_tween.kill()
	reposition_tween.kill()
	player.position = newpos
	player.set_animation('slip_backward')
	player.quick_heal(Util.get_hazard_damage(base_damage))
	AudioManager.play_sound(SFX_LAND)
	await Task.delay(2.75)
	player.toon.body_node.rotation_degrees = Vector3.ZERO
	player.state = Player.PlayerState.WALK
	if Util.get_player().stats.hp <= 0:
		Util.get_player().lose()
