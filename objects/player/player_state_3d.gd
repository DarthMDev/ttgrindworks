extends State3D
class_name PlayerState3D

@onready var player: Player = owner
@onready var toon: Toon = %Toon
@onready var camera: PlayerCamera = %PlayerCamera
@onready var move_sfx: AudioStreamPlayer = %MoveSFX

#region Override this in subclasses

func handle_movement(_delta: float) -> void:
	return

# Return true if we allow player interaction (pauses, etc), false if not.
func accepts_interaction() -> bool:
	return false

#endregion

var stats: PlayerStats:
	get: return player.stats

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_sfx()

#region Movement and velocity

const TURN_SPEED := 120.0

var speed = 0.0
var can_sprint := true
var sprint: bool

var moving := false:
	set(x):
		moving = x
		if control_style or player.state == Player.PlayerState.CHASE:
			assess_anim()

var velocity: Vector3:
	get: return player.velocity
	set(x): player.velocity = x
func get_run_speed() -> float:
	return run_speed * stats.get_stat('speed')

var run_speed: float:
	get: return player.run_speed

var control_style: bool:
	get: return SaveFileService.settings_file.control_style

func handle_default_movement(delta: float) -> void:
	apply_gravity(delta)

	# Get current movement speed
	var target_speed = get_run_speed()
	sprint = should_sprint()
	if not sprint: target_speed /= 2.0
	
	if speed != target_speed:
		speed = lerp(speed, target_speed, 0.2)
	
	if control_style:
		_movement_style_standard(delta)
	else:
		_movement_style_tank(delta)
	
	player.move_and_slide()

func _calc_movement_style_standard(origin: Node3D = camera) -> Vector3:
	# Get the input/direction vectors
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# For mouse controls
	if Input.is_action_pressed('mouse_forward'):
		input_dir = Input.get_vector('move_left', 'move_right', 'mouse_forward', 'move_back')
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3(0, 1, 0), origin.global_rotation.y)
	if direction:
		moving = true
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		moving = false
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
	return direction

func _movement_style_standard(_delta: float, origin: Node3D = camera) -> void:
	var direction := _calc_movement_style_standard(origin)
	# Turn to face moving direction
	if direction:
		toon.rotation.y = lerp_angle(toon.rotation.y, atan2(direction.x, direction.z), .3)	

func _calc_movement_style_tank() -> Array:
	var input_dir := Input.get_axis('move_back','move_forward')
	if input_dir == -1 and sprint: 
		speed = (run_speed * stats.get_stat('speed')) / 2.0
	var direction = (toon.transform.basis * Vector3(0, 0, input_dir)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	var input_turn := Input.get_axis("move_left", "move_right")
	moving = (direction or input_turn)
	return [input_dir, input_turn, direction]

func _movement_style_tank(delta: float) -> void:
	var input := _calc_movement_style_tank()
	var input_dir: float = input[0]
	var input_turn: float = input[1]
	var turn_speed := TURN_SPEED * player.stats.get_stat('speed')
	toon.rotation.y += (deg_to_rad(turn_speed * delta) * -input_turn)
	camera.rotation.y += (deg_to_rad(turn_speed * delta) * -input_turn)
	
	if is_on_floor() and not Input.is_action_just_pressed("jump") and can_jump:
		if input_dir == 1 and sprint:
			set_animation('run')
		elif input_turn or input_dir:
			if input_dir == -1:
				toon.set_animation('walk', -1, -1.0)
			else:
				toon.set_animation('walk')
		else:
			set_animation('neutral')

func should_sprint() -> bool:
	if not can_sprint:
		return false
	
	if SaveFileService.settings_file.auto_sprint:
		return not Input.is_action_pressed('sprint')
	else:
		return Input.is_action_pressed('sprint')

#endregion
#region Jumping and Gravity

const COYOTE_TIME := 0.07
const EXTRA_JUMP_DELAY := 0.6

var can_jump := true
var jump_velocity := 7.0
var jump_velocity_mult := 1.0
var gravity:
	get:
		return player.gravity
var last_floor_time: float = 0.0

var _extra_jump_task: Task
var _extra_jumps_remaining := 0
var _extra_jump_ready := false
var _using_extra_jumps := false

func is_on_floor() -> bool:
	return player.is_on_floor()

func is_jumpable() -> bool:
	return _extra_jump_ready or is_on_floor() or (Time.get_unix_time_from_system() - last_floor_time) < COYOTE_TIME

func handle_jump(_delta: float) -> void:
	# Jump/Gravity
	if is_jumpable():
		if is_on_floor():
			last_floor_time = Time.get_unix_time_from_system()
			clear_extra_jumps()
		
		var jump_pressed := Input.is_action_just_pressed('jump')
		if not jump_pressed and control_style:
			jump_pressed = Input.is_action_just_pressed('mouse_jump')
		
		if jump_pressed and can_jump:
			velocity.y = (jump_velocity * jump_velocity_mult) * stats.agility
			var platform_velocity := player.get_platform_velocity().y
			if platform_velocity > 0.0:
				velocity.y += platform_velocity

			check_extra_jumps()

			SaveFileService.progress_file.times_jumped += 1
			player.s_jumped.emit()
			Globals.s_player_jumped.emit()
			if moving: 
				set_animation('zhang')
			else: 
				set_animation('jump-zhang')

func check_extra_jumps(from_jump := true) -> void:
	if _using_extra_jumps and from_jump:
		_extra_jumps_remaining -= 1
		_extra_jump_ready = false
		if _extra_jumps_remaining > 0:
			_extra_jump_task = Task.delayed_call(self, EXTRA_JUMP_DELAY, _make_extra_jump_ready)
	else:
		if player.stats.extra_jumps > 0 and (from_jump or not _using_extra_jumps):
			_extra_jumps_remaining = player.stats.extra_jumps
			_using_extra_jumps = true
			jump_velocity_mult = 0.75
			_extra_jump_task = Task.delayed_call(self, EXTRA_JUMP_DELAY if from_jump else COYOTE_TIME, _make_extra_jump_ready)

func _make_extra_jump_ready():
	_extra_jump_ready = true
	player.toon.color_overlay_mat.flash_instant_fade(self, Color("de73ffff"), 0.225, 0.15)
	AudioManager.play_sound(load("res://audio/sfx/ui/GUI_balloon_popup.ogg"), 3.0)

func clear_extra_jumps() -> void:
	_extra_jumps_remaining = 0
	_extra_jump_ready = false
	_using_extra_jumps = false
	jump_velocity_mult = 1.0
	if _extra_jump_task:
		_extra_jump_task = _extra_jump_task.cancel()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		check_extra_jumps(false)

#endregion
#region Animation and SFX

const SFX_WALK := preload('res://audio/sfx/toon/AV_footstep_walkloop.ogg')
const SFX_RUN := preload('res://audio/sfx/toon/AV_footstep_runloop.ogg')

var base_anim := 'neutral'
var animator: AnimationPlayer

func handle_sfx() -> void:
	if get_animation() == 'walk':
		if move_sfx.stream != SFX_WALK:
			move_sfx.stream = SFX_WALK
			move_sfx.play()
	elif get_animation() == 'run':
		if move_sfx.stream != SFX_RUN:
			move_sfx.stream = SFX_RUN
			move_sfx.play()
	elif move_sfx.stream:
		move_sfx.stop()
		move_sfx.stream = null

func get_animation() -> String:
	return player.get_animation()

func assess_anim() -> void:
	var anim := base_anim
	if is_on_floor() and not (Input.is_action_just_pressed('jump') or Input.is_action_just_pressed('mouse_jump')):
		if moving:
			if sprint:
				anim = 'run'
			else:
				anim = 'walk'
		if not get_animation() == anim:
			set_animation(anim)

func set_animation(anim : String, _speed := 1.0):
	if not get_animation() == anim:
		toon.set_animation(anim)

#endregion
#region Camera

func capture_mouse() -> void:
	if Util.window_focused and not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_camera() -> void:
	# Camera zoom
	if Input.is_action_just_pressed('zoom_in'):
		player.camera_dist = max(player.camera_dist-0.5,1.5)
	elif Input.is_action_just_pressed('zoom_out'):
		player.camera_dist = min(player.camera_dist+0.5,4.0)
	
	# Camera sprint FOV
	if sprint:
		if camera.fov < 60:
			camera.fov = lerp(camera.fov,60.0,0.15)
	elif camera.fov > 52:
		camera.fov = lerp(camera.fov,52.0,0.15)
	
	if Input.is_action_just_pressed('toggle_freecam') and SaveFileService.settings_file.dev_tools:
		var cam := PlayerFreeCam.new(player)
		cam.fov = camera.fov
		player.add_child(cam)
		cam.global_transform = camera.camera.global_transform
		set_animation('neutral')
	
	if Input.is_action_just_pressed('recenter_camera'):
		player.recenter_camera(false)

#endregion

const DEBUG_COLLISION_PRINT := false

func debug_collision_check() -> void:
	if DEBUG_COLLISION_PRINT and OS.is_debug_build():
		var kc3d: KinematicCollision3D = player.get_last_slide_collision()
		if kc3d:
			print(get_tree().root.get_path_to(kc3d.get_collider(0)))
