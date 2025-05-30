extends Node3D

const SLAM_SFX := preload("res://audio/sfx/battle/gags/drop/AA_drop_bigweight_miss.ogg")
const EXPLODE_SFX := preload("res://audio/sfx/battle/cogs/ENC_cogfall_apart.ogg")
const SFX_SWAP := preload("res://audio/sfx/objects/facility_door/CHQ_FACT_door_unlock.ogg")
const SFX_HIT = preload("res://audio/sfx/misc/CHQ_SOS_cage_land.ogg")

const REGULAR_OBJS: Array[PackedScene] = [
	preload("res://objects/modules/mint/variants/golden_goose_obj_safe.tscn"),
	preload("res://objects/modules/mint/variants/golden_goose_obj_double_safe.tscn")
]

const BUTTON_OBJ: PackedScene = preload("res://objects/modules/mint/variants/golden_goose_obj_button.tscn")

const HIT_DIALOGUE := [
	"HEY! Gold is delicate, you ingrate!",
	"MY PRECIOUS PLATING!!!!!",
	"YOU'RE REALLY RUFFLING MY FEATHERS, TOON.",
	"QUIT EGGING ME ON.",
	"I'LL SCRAMBLE YOU.",
	"HOOOOOOONK!!!!!!",
]

var BOSS_MUSIC = GameLoader.load("res://audio/music/action_cash.ogg")
const EXPLOSION := preload("res://models/cogs/misc/explosion/cog_explosion.tscn")

@onready var drop_shadow_template: Node3D = %DropShadowTemplate

var game_stompers: Array[Node3D] = []
var active_stompers: Array[Node3D] = []
var objs_a: Array[Node3D] = []
var objs_b: Array[Node3D] = []
var game_started := false
var stomper_task: Task
var obj_task: Task
var health := 3
var conveyor_speed: float = 0.0:
	set(x):
		conveyor_speed = x
		if is_node_ready():
			conveyor_tween = Parallel.new([
				LerpProperty.new(%CB1, ^"speed", 1.5, conveyor_speed).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
				LerpProperty.new(%CB2, ^"speed", 1.5, conveyor_speed).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
				LerpProperty.new(self, ^"obj_a_speed", 1.5, conveyor_speed).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
				LerpProperty.new(self, ^"obj_b_speed", 1.5, conveyor_speed).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
			]).as_tween(self)
var conveyor_mult: float = 1.0
var obj_a_speed: float = 0.0:
	set(x):
		obj_a_speed = x
		if is_node_ready():
			for obj: Node3D in objs_a:
				obj.speed = obj_a_speed * -1.0
var obj_b_speed: float = 0.0:
	set(x):
		obj_b_speed = x
		if is_node_ready():
			for obj: Node3D in objs_b:
				obj.speed = obj_b_speed

var fall_tween: Tween:
	set(x):
		if fall_tween and fall_tween.is_valid():
			fall_tween.kill()
		fall_tween = x
var conveyor_tween: Tween:
	set(x):
		if conveyor_tween and conveyor_tween.is_valid():
			conveyor_tween.kill()
		conveyor_tween = x
var goose_tween: Tween:
	set(x):
		if goose_tween and goose_tween.is_valid():
			goose_tween.kill()
		goose_tween = x
var stomper_tweens: Dictionary = {}
var base_speed : float:
	get:
		if Util.on_easy_floor(): return 7.25
		return 10.0
var speed_mult : float:
	get:
		if Util.on_easy_floor(): return 2.5
		return 3.0

var button_quota := 0

func set_conveyor_coll_enabled(enabled: bool) -> void:
	for child: CollisionShape3D in %ConveyorColl.get_children():
		child.disabled = not enabled

func _ready():
	set_conveyor_coll_enabled.call_deferred(false)
	game_stompers.assign(%GameStompersUp.get_children() + %GameStompersDown.get_children())
	%Goose.set_animation("slip-backward")
	%Goose.animator.seek(1.2, true)
	%Goose.pause_animator()

func body_entered(body: Node3D) -> void:
	if game_started:
		return
	if not body is Player:
		return

	game_started = true
	run_intro()

func run_intro() -> void:
	var player: Player = Util.get_player()
	%SkipButton.show()
	
	var intro_tween := create_tween()
	# Setup
	intro_tween.tween_callback(
		func(): 
			player.state = Player.PlayerState.STOPPED
			player.game_timer_tick = false
			player.set_animation('neutral')
			player.apply_floor_snap()
			Util.stuck_lock = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	)
	
	# Pan Camera to Golden Goose
	intro_tween.tween_callback(CameraTransition.from_current.bind(self, %GooseCam, 3.0))
	intro_tween.tween_interval(3.0)
	
	# Goose dial
	intro_tween.tween_callback(%Goose.speak.bind("What's this? A TOON? IN MY TREASURY?"))
	intro_tween.tween_callback(%Goose.animator.play)
	intro_tween.tween_interval(4.0)
	intro_tween.tween_callback(%Goose.speak.bind("You think you can WALTZ IN and put your GRUBBY MITTS on MY gold!?!"))
	intro_tween.tween_interval(3.0)
	intro_tween.tween_callback(%Goose.speak.bind("Never! NEVER! [shake rate=30 level=15]NEVER!!!!!"))
	intro_tween.tween_callback(%Goose.set_animation.bind('jump'))
	
	# Move player to start position
	intro_tween.tween_callback(
		func():
			player.global_position = %SPAWNPOINT.global_position
			player.toon.global_rotation = %SPAWNPOINT.global_rotation
	)
	intro_tween.tween_interval(3.5)
	
	# Make blockers fall into place
	intro_tween.tween_callback(%BlockerCam.make_current)
	intro_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	intro_tween.tween_property(%Fallers, 'position', Vector3.ZERO, 1.5)
	intro_tween.parallel().tween_callback(AudioManager.play_sound.bind(SLAM_SFX)).set_delay(0.5)
	intro_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	intro_tween.tween_interval(0.25)
	
	# Final Goose dial
	intro_tween.tween_callback(%GooseCam.make_current)
	intro_tween.tween_callback(%Goose.set_animation.bind('effort'))
	intro_tween.tween_callback(%Goose.animator_seek.bind(3.25))
	intro_tween.tween_callback(%Goose.speak.bind("YOU'LL NEVER TAKE MY NEST EGG!!!!"))
	intro_tween.tween_interval(3.0)
	intro_tween.tween_callback(%SkipButton.hide)
	intro_tween.tween_callback(begin_game)
	intro_tween.finished.connect(intro_tween.kill)
	
	%SkipButton.pressed.connect(skip_cutscene.bind(intro_tween))

func skip_cutscene(intro_tween: Tween) -> void:
	intro_tween.custom_step(10000.0)
	%Goose.set_animation('neutral')

func get_random_object_time() -> float:
	return RandomService.randf_range_channel('golden_goose', 1.1, 1.9) - (0.35 * get_missing_health())

func get_random_stomp_time() -> float:
	return RandomService.randf_range_channel('golden_goose', 1.0, 2.1) - (0.17 * get_missing_health())

func begin_game() -> void:
	Util.get_player().game_timer_tick = true
	set_conveyor_coll_enabled.call_deferred(true)
	Util.get_player().camera.make_current()
	Util.get_player().state = Player.PlayerState.WALK
	AudioManager.set_music(BOSS_MUSIC)
	button_quota = get_button_quota()
	randomize_conveyor_speed()
	stomper_task = Task.delayed_call(self, get_random_stomp_time(), random_stomp)
	obj_task = Task.delayed_call(self, get_random_object_time(), spawn_random_obj)

func random_stomp(add_task := true) -> void:
	var available_stompers: Array[Node3D] = game_stompers.filter(func(x: Node3D): return x not in active_stompers)
	if add_task:
		stomper_task = Task.delayed_call(self, get_random_stomp_time(), random_stomp)
	if available_stompers.size() == 0:
		return

	if get_missing_health() == 2 and RandomService.randf_channel('golden_goose') < 0.2:
		# When golden goose is on their last HP, small chance to do 2 stompers.
		random_stomp(false)

	var chosen_stomper: Node3D = RandomService.array_pick_random('golden_goose', available_stompers)
	active_stompers.append(chosen_stomper)
	var new_shadow: Node3D = drop_shadow_template.duplicate()
	add_child(new_shadow)
	new_shadow.global_position = Vector3(chosen_stomper.global_position.x, drop_shadow_template.global_position.y + 0.01, chosen_stomper.global_position.z)
	var shadow_mat: StandardMaterial3D = new_shadow.get_node("Mesh").mesh.material.duplicate()
	new_shadow.get_node("Mesh").set_surface_override_material(0, shadow_mat)
	shadow_mat.albedo_color.a = 0.0
	new_shadow.show()
	stomper_tweens[chosen_stomper] = Sequence.new([
		LerpProperty.new(shadow_mat, ^"albedo_color:a", 1.25, 0.85).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
		Wait.new(0.75),
		Func.new(chosen_stomper.do_stomp),
		Wait.new(0.5),
		LerpProperty.new(shadow_mat, ^"albedo_color:a", 0.5, 0.0).interp(Tween.EASE_IN, Tween.TRANS_QUAD),
		Func.new(new_shadow.queue_free),
		Func.new(func(): if chosen_stomper in active_stompers: active_stompers.erase(chosen_stomper)),
	]).as_tween(self)

func get_missing_health() -> int:
	return 3 - health

func randomize_conveyor_speed() -> void:
	conveyor_mult = -conveyor_mult
	conveyor_speed = (base_speed + (get_missing_health() * speed_mult)) * conveyor_mult

func deal_damage() -> void:
	health -= 1
	if health == 0:
		# Make the stomper kill Everything
		%GooseStomper.floor_position -= 0.58
		%EntranceStomper.do_stomp()
	%GooseStomper.do_stomp()
	await Task.delay(0.09)
	if health > 0:
		AudioManager.play_sound(SFX_HIT)
		%Goose.set_animation("slip-backward")
		goose_tween = Sequence.new([
			LerpProperty.new(%Goose, ^"scale", 0.11, Vector3(1, 0.01, 1)),
			Wait.new(0.7),
			LerpProperty.new(%Goose, ^"scale", 0.7, Vector3.ONE).interp(Tween.EASE_OUT, Tween.TRANS_BOUNCE),
		]).as_tween(self)
		await Task.delay(2.0)
		%Goose.speak(RandomService.array_pick_random('golden_goose', HIT_DIALOGUE))
		randomize_conveyor_speed()
		AudioManager.play_sound(SFX_SWAP)
	else:
		win_game()

func win_game() -> void:
	Util.stuck_lock = false
	conveyor_speed = 0
	if stomper_task:
		stomper_task = stomper_task.cancel()
	if obj_task:
		obj_task = obj_task.cancel()
	Util.get_player().stats.charge_active_item(2)

	make_explosion(%Goose.global_position)
	%Goose.hide()
	# Move it physically so that the collision doesn't stick around
	%CrushCrate.position.y -= 50
	%Fallers.position.y -= 50
	AudioManager.stop_music()
	await get_tree().process_frame
	%WallReset.monitoring = false
	set_conveyor_coll_enabled.call_deferred(false)
	%BossChestGroup.make_chests()
	BattleService.s_boss_died.emit(%Goose)
	SaveFileService.progress_file.cogs_defeated[%Goose.dna.cog_name] = SaveFileService.progress_file.cogs_defeated.get_or_add(%Goose.dna.cog_name, 0) + 1
	%DeadGoose.set_animation('goose-lose')
	%DeadGoose.animator.pause()
	%DeadGoose.animator.seek(0.0)
	%DeadGoose.drop_shadow.hide()
	%DeadGoose.body.nametag_node.hide()
	%DeadGoose.body.department_emblem.hide()
	%DeadGoose.body.head_bone.override_pose = true
	%DeadGoose.body.head_bone.position = Vector3(0, 0, -5.6)
	%DeadGoose.show()

func spawn_random_obj() -> void:
	var is_button := false
	if button_quota <= 0:
		button_quota = get_button_quota()
		is_button = true

	obj_task = Task.delayed_call(self, get_random_object_time(), spawn_random_obj)
	var side: String = RandomService.array_pick_random('golden_goose', ["a", "b"])
	var spawn_point: Node3D
	var obj_arr: Array[Node3D]
	var holder_node: Node3D
	if side == "a":
		spawn_point = %SpawnPointA if is_equal_approx(conveyor_mult, -1.0) else %SpawnPointA2
		obj_arr = objs_a
		holder_node = %ObjsA
	else:
		spawn_point = %SpawnPointB if is_equal_approx(conveyor_mult, -1.0) else %SpawnPointB2
		obj_arr = objs_b
		holder_node = %ObjsB

	var new_obj: Node3D
	if is_button:
		new_obj = BUTTON_OBJ.instantiate()
		new_obj.get_node("Button").s_pressed.connect(deal_damage.unbind(1))
	else:
		new_obj = get_random_object().instantiate()
	holder_node.add_child(new_obj)
	new_obj.global_position = spawn_point.global_position
	obj_arr.append(new_obj)
	new_obj.speed = (obj_a_speed * -1.0 if side == "a" else obj_b_speed)
	new_obj.tree_exited.connect(func(): if new_obj in obj_arr: obj_arr.erase(new_obj))
	new_obj.s_stomped.connect(func(): make_explosion(new_obj.global_position))

	button_quota -= 1

func get_button_quota() -> int:
	return 8 + (get_missing_health() * 8)

func _exit_tree() -> void:
	if stomper_task:
		stomper_task = stomper_task.cancel()
	if obj_task:
		obj_task = obj_task.cancel()
	stomper_tweens = {}

func make_explosion(pos: Vector3) -> void:
	var new_explosion: AnimatedSprite3D = EXPLOSION.instantiate()
	add_child(new_explosion)
	new_explosion.global_position = pos
	new_explosion.scale = Vector3.ONE * 25.0
	AudioManager.play_sound(EXPLODE_SFX, -4.0)
	new_explosion.play('explode')
	await new_explosion.animation_finished
	new_explosion.queue_free()

func get_random_object() -> PackedScene:
	if Util.on_easy_floor() or RandomService.randi_channel('true_random') % 3 > 0:
		return REGULAR_OBJS[0]
	return RandomService.array_pick_random('golden_goose', REGULAR_OBJS)
