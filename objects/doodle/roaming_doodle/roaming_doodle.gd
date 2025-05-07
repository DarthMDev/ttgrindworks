extends Actor
class_name RoamingDoodle

const FOLLOW_DISTANCE := 10.0
const MAX_DISTANCE := 20.0
const SAFE_DISTANCE := 5.0
const NAV_RADIUS := 5.0
const WALK_SPD := 2.0
const GRAVITY := -9.8
const DIG_CHANCE := 2
const CHEST_CHANCE := 2
const TREASURE_POOL := preload("res://objects/items/pools/doodle_treasure.tres")

## ANIM CONSTANTS
const TELEPORT_HOLE := preload('res://objects/misc/teleport_hole/teleport_hole.tscn')
# Direct references to treasure chest here cause a cyclical reference error :(
const TREASURE_CHEST := "res://objects/interactables/treasure_chest/treasure_chest.tscn"
const SFX_TP := preload('res://audio/sfx/doodle/teleport_disappear.ogg')
const SFX_TP_IN := preload('res://audio/sfx/doodle/teleport_reappear.ogg')
const SFX_DIG := preload('res://audio/sfx/doodle/burrow.ogg')
const SFX_TREASURE := preload('res://audio/sfx/doodle/treasure_digup.ogg')
const SFX_DANCE := preload('res://audio/sfx/doodle/heal_dance.ogg')


enum DoodleState {
	STOPPED,
	TRANSITION,
	NAVIGATE,
	DIG,
	BATTLE,
	AWAIT,
}
@export var state := DoodleState.STOPPED:
	set(x):
		_state_change(state,x)
		state = x
enum DoodleMood {
	NEUTRAL,
	HAPPY,
	SAD
}
@export var mood := DoodleMood.HAPPY

@export var doodle_actions : Array[DoodleAction]

@onready var nav : NavigationAgent3D = $NavAgent
@onready var nav_timer : Timer = $NavPauseTimer
@onready var head_node := $Head
@onready var doodle : Doodle = $Doodle
@onready var shadow := $DropShadow
@onready var hole_placement : Node3D = $Doodle/HolePlacement
@onready var animator : AnimationPlayer = $Doodle/AnimationPlayer
@onready var sfx_player : AudioStreamPlayer3D = $SFX

# Navigation values
var want_goal := true
var following_player := false
var nav_pause_range := Vector2(3.0,10.0)
var player : Player:
	get: return Util.get_player()
var prev_pos : Vector3

# Anim Tracking
var hole : Node3D
# Treasure chest is a class
# But referencing it here causes a cyclical reference
var chest : Node3D
# Should be reused for any interruptible behavior
# Such as: digging, teleporting, etc.
var tween : Tween

## Misc
var item : Item: # For arbitrary value storage
	set(x):
		item = x
		sync_item()

func _physics_process(delta : float) -> void:
	match state:
		DoodleState.NAVIGATE:
			_physics_process_nav(delta)
		DoodleState.AWAIT:
			_physics_process_await(delta)
		DoodleState.STOPPED:
			return
		DoodleState.BATTLE:
			return
		_:
			if not is_on_floor():
				velocity.y += GRAVITY * delta
			move_and_slide()
	
	
	$Label.set_text(
		"State: " + DoodleState.keys()[state as int] 
		+"\nWant goal: "+str(want_goal)
		+"\nMood: " + get_mood_string(mood).to_upper()
		+"\nFollowing: " + str(following_player)
	)

func _physics_process_nav(delta : float) -> void:
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if not want_goal:
		return
	
	# Test for player distance
	if get_player_dist() > MAX_DISTANCE:
		teleport_away(DoodleState.AWAIT)
		return
	
	# Try for a new position once per frame if not reachable
	if (not nav.is_target_reachable() and not following_player) or is_target_reached():
		following_player = get_player_dist() > FOLLOW_DISTANCE
		nav.target_position = get_goal_pos()
		return
	
	# Following behaviors
	if following_player:
		# Target pos has to be updated every frame if following player
		nav.target_position = get_goal_pos()
		# Teleport away if player is in un-navigable area
		if not nav.is_target_reachable() and player.is_on_floor() and get_player_dist() > SAFE_DISTANCE:
			teleport_away(DoodleState.AWAIT)
			want_goal = false
			return
	
	# NAVIGATE
	# Get the next path pos
	var next_pos := nav.get_next_path_position()
	
	# Face towards the position
	var dir := global_position.direction_to(next_pos)
	doodle.rotation.y = lerp_angle(doodle.rotation.y,atan2(dir.x,dir.z),.15)
	
	# Move towards position
	global_position = global_position.move_toward(next_pos,delta * WALK_SPD)
	
	# Ensure Doodle is walking while navigating
	if not get_animation() == 'walk':
		set_animation('walk')
	
	# Move and slide to collide with stuff and all that
	move_and_slide()
	
	# Ensure Doodle won't endlessly walk into wall
	# Compare on x/z axis only
	if prev_pos and not following_player:
		if Vector2(global_position.x,global_position.z).is_equal_approx(Vector2(prev_pos.x,prev_pos.z)):
			goal_reached(false)
	
	# Keep track of previous position
	prev_pos = global_position 

func _physics_process_await(_delta) -> void:
	if not player:
		return
	
	# Go to a random position near the player
	global_position = player.position
	global_position.x += RandomService.randf_range_channel('doodle_dig', -NAV_RADIUS / 2.0, NAV_RADIUS / 2.0)
	global_position.z += RandomService.randf_range_channel('doodle_dig', -NAV_RADIUS / 2.0, NAV_RADIUS / 2.0)
	
	# If you can walk to the player from here, it's (probably) a legal space.
	nav.target_position = player.global_position
	if nav.is_target_reachable():
		teleport_in(DoodleState.NAVIGATE)

func get_goal_pos() -> Vector3:
	if following_player:
		return player.global_position
	else:
		var new_pos := global_position
		new_pos.x += RandomService.randf_range_channel('doodle_dig', -NAV_RADIUS, NAV_RADIUS)
		new_pos.z += RandomService.randf_range_channel('doodle_dig', -NAV_RADIUS, NAV_RADIUS)
		return new_pos

func goal_reached(try_for_dig := true) -> void:
	# Protect against navigator calling this at weird times
	if not state == DoodleState.NAVIGATE:
		return
	
	want_goal = false
	set_animation('neutral')
	if not following_player and try_for_dig and RandomService.randi_channel('doodle_dig') % DIG_CHANCE == 0 and mood == DoodleMood.HAPPY:
		dig()
	else:
		nav_reset()
	following_player = false

func nav_reset() -> void:
	nav.target_position = get_goal_pos()
	reset_timer()

func reset_timer() -> void:
	nav_timer.wait_time = RandomService.randf_range_channel('doodle_dig', nav_pause_range.x, nav_pause_range.y)
	nav_timer.start()

func nav_pause_finished() -> void:
	if state == DoodleState.NAVIGATE:
		want_goal = true

func get_player_dist() -> float:
	if not player:
		return 0.0
	else:
		return global_position.distance_to(player.global_position)

func is_target_reached() -> bool:
	return global_position.distance_to(nav.target_position) < nav.target_desired_distance

func set_goal_pos(pos : Vector3) -> void:
	nav.target_position = pos

func set_animation(anim : String) -> void:
	if animator.has_animation(anim + "_" + get_mood_string(mood)):
		doodle.set_animation(anim + "_" + get_mood_string(mood))
	else:
		doodle.set_animation(anim)

func get_mood_string(doodle_mood : DoodleMood) -> String:
	return str(DoodleMood.keys()[doodle_mood as int]).to_lower()

func get_animation() -> String:
	return doodle.animator.current_animation

func face_position(pos : Vector3) -> void:
	var rot : Vector3 = doodle.rotation
	doodle.look_at(pos)
	rot.y = doodle.rotation.y
	doodle.rotation = rot
	doodle.rotation_degrees.y -= 180.0

## Object reacts to battle starting
func battle_started(battle : BattleNode) -> void:
	if state == DoodleState.STOPPED:
		return
	
	# Teleport away, and then back in for battle
	teleport_away(DoodleState.STOPPED)
	tween.finished.connect(func(): 
		global_position = battle.get_partner_position(player.partners.find(self))
		face_position(battle.global_position)
		teleport_in(DoodleState.BATTLE)
		tween.finished.connect(
		func(): 
			s_battle_ready.emit()
			set_animation('neutral')
		)
	)
	
	battle.s_battle_ending.connect(battle_ending)
	battle.s_battle_end.connect(battle_ended)

func get_attack() -> DoodleAction:
	if not doodle_actions.is_empty():
		var action := doodle_actions[RandomService.randi_channel('true_random') % doodle_actions.size()]
		action = action.duplicate()
		action.user = self
		action.targets = [player]
		return action
	return null

func teleport_away(new_state := DoodleState.STOPPED) -> void:
	state = DoodleState.TRANSITION
	
	# Create the hole object
	hole = TELEPORT_HOLE.instantiate()
	hole_placement.add_child(hole)
	hole.scale *= 0.4
	var hole_animator : AnimationPlayer = hole.get_node('AnimationPlayer')
	
	# Kill the old tween if it exists
	if tween:
		tween.kill()
	
	# Play the tp sfx
	play_sfx(SFX_TP)
	
	# Create new teleport tween
	tween = create_tween()
	tween.tween_callback(set_animation.bind('into_dig'))
	tween.tween_callback(hole_animator.play.bind('grow'))
	tween.tween_interval(1.0833)
	tween.tween_callback(set_animation.bind('dig'))
	tween.tween_interval(0.4583)
	tween.tween_callback(set_animation.bind('disappear'))
	tween.tween_interval(1.3333)
	tween.tween_callback(hole_animator.play.bind('shrink'))
	tween.tween_interval(0.5)
	tween.tween_callback(shadow.hide)
	tween.tween_callback(doodle.hide)
	tween.tween_callback(hole.queue_free)
	
	# Hook tween finish up to a state swap
	tween.finished.connect(func(): state = new_state)

func teleport_in(new_state := DoodleState.STOPPED) -> void:
	state = DoodleState.TRANSITION
	
	# Create the hole
	hole = TELEPORT_HOLE.instantiate()
	hole_placement.add_child(hole)
	hole.scale *= 0.4
	var hole_animator : AnimationPlayer = hole.get_node('AnimationPlayer')
	
	# Play the sfx
	play_sfx(SFX_TP_IN)
	
	# Create the tween
	tween = create_tween()
	tween.tween_callback(doodle.show)
	tween.tween_callback(shadow.show)
	tween.tween_callback(set_animation.bind('appear'))
	tween.tween_callback(hole_animator.play.bind('grow'))
	tween.tween_interval(0.5)
	tween.tween_callback(hole_animator.play.bind('shrink'))
	tween.tween_interval(0.5)
	tween.tween_callback(hole.queue_free)
	tween.finished.connect(func(): state = new_state)

func dig() -> void:
	state = DoodleState.DIG
	
	# Roll for chest digup
	var success := RandomService.randi_channel('doodle_chests') % CHEST_CHANCE == 0
	
	# Create the hole
	hole = TELEPORT_HOLE.instantiate()
	hole_placement.add_child(hole)
	hole.scale *= 0.4
	var hole_animator : AnimationPlayer = hole.get_node('AnimationPlayer')
	
	# Play the sfx
	play_sfx(SFX_DIG)
	
	# Create the tween
	tween = create_tween()
	tween.tween_callback(hole_animator.play.bind('grow'))
	tween.tween_callback(set_animation.bind('into_dig'))
	tween.tween_interval(1.0833)
	tween.tween_callback(set_animation.bind('dig'))
	tween.tween_interval(1.0)
	tween.tween_callback(set_animation.bind('neutral'))
	
	if success:
		# Create the chest
		chest = load(TREASURE_CHEST).instantiate()
		if is_instance_valid(Util.floor_manager):
			Util.floor_manager.get_current_room().add_child(chest)
		elif is_instance_valid(SceneLoader.current_scene):
			SceneLoader.current_scene.add_child(chest)
		chest.hide()
		chest.global_rotation_degrees.y = doodle.global_rotation_degrees.y - 180.0
		chest.global_position = hole_placement.global_position
		chest.global_position.y -= 4.0
		chest.item_pool = TREASURE_POOL
		# Create tween remainder
		tween.tween_callback(AudioManager.play_sound.bind(SFX_TREASURE))
		tween.tween_callback(chest.show)
		tween.tween_property(chest,'global_position:y',4.0,0.5).as_relative()
		mood = DoodleMood.NEUTRAL
	
	# Doodle should run very excitedly to player to show them
	# The very cool and awesome treasure they dug up
	tween.finished.connect(
		func(): 
			chest = null
			state = DoodleState.NAVIGATE
	)

func sync_item() -> void:
	if item.arbitrary_data.has('mood'):
		mood = item.arbitrary_data['mood']
	else:
		item.arbitrary_data['mood'] = mood

func clear_props() -> void:
	if is_instance_valid(hole):
		hole.queue_free()
	if is_instance_valid(chest):
		chest.queue_free()

func cancel_anim() -> void:
	clear_props()
	if tween: tween.kill()

func battle_ending() -> void:
	set_animation('dance')
	play_sfx(SFX_DANCE)


func battle_ended() -> void:
	if not mood == DoodleMood.HAPPY and RandomService.randi_channel('doodle_mood') % 4 == 0:
		mood = DoodleMood.HAPPY
	state = DoodleState.NAVIGATE

@warning_ignore("unused_parameter")
func _state_change(old_state : DoodleState, new_state : DoodleState) -> void:
	cancel_anim()
	
	# State-specific changes
	match new_state:
		DoodleState.NAVIGATE:
			want_goal = true
			following_player = true

func play_sfx(stream : AudioStream) -> void:
	sfx_player.set_stream(stream)
	sfx_player.play()
