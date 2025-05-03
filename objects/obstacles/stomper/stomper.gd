@tool
extends Node3D

enum StomperModel { SELLBOT, LAWBOT }
const MODEL_PATHS = {
	StomperModel.SELLBOT: ^'Model/stomper',
	StomperModel.LAWBOT: ^'Model/law_stomper',
}
const DEFAULT_HEAD_POS := Vector3(0, 0, -4.649)
const SHAFT_SIZE := 9.234

const STOMP_TIME := 0.2
const SFX_DECOMPRESS := preload("res://audio/sfx/objects/stomper/toon_decompress.ogg")
const SFX_RAISE := preload("res://audio/sfx/objects/stomper/CHQ_FACT_stomper_raise.ogg")
const SFX_STOMP_DEFAULT := preload("res://audio/sfx/objects/stomper/CHQ_FACT_stomper_med.ogg")

@export_group("Visuals")
@export var model: StomperModel:
	set(new):
		model = new
		model_path = MODEL_PATHS[model]
		if is_node_ready():
			_update_model_node()
@export var head_position := DEFAULT_HEAD_POS:
	set(new):
		head_position = new
		if is_node_ready():
			model_head.position = head_position
			_update_model_scale()
@export_custom(PROPERTY_HINT_LINK, '') var head_scale := Vector3.ONE:
	set(new):
		head_scale = new
		if is_node_ready():
			model_head.scale = head_scale
			_update_model_scale()
@export_range(0.005, 20, 0.005, 'or_greater', 'hide_slider') var shaft_scale := 1.0:
	set(new):
		shaft_scale = new
		if is_node_ready():
			model_shaft.scale.z = shaft_scale
			_update_model_scale()
@export var show_collisions: bool:
	set(new):
		show_collisions = new
		if is_node_ready():
			_update_show_collisions()
@export_group('Animation')
@export var only_stomp_when_called := false
var collisions: Array[CollisionShape3D]
@export_range(0.005, 20, 0.005, 'or_greater', 'hide_slider') var raise_height := 1.0
@export var raise_time := 1.0
@export var raise_time_offset := 0.0
@export_group('Sound')
@export var stomp_sfx: AudioStream = SFX_STOMP_DEFAULT
@export_group('Player Interaction')
@export var base_damage := -4

var model_path: NodePath = ^'Model/stomper'
#var model_node: Node3D
var model_head: Node3D
var model_shaft: Node3D
@onready var model_node: Node3D = %Model
@onready var sfx_player: AudioStreamPlayer3D = %SFXPlayer
@onready var delay_timer : Timer = %DelayTimer

@onready var head_collision: StaticBody3D = %Model/HeadCollision
@onready var shaft_collision_shape: CollisionShape3D = %Model/ShaftCollision/CollisionShape3D
@onready var player_detection: Area3D = %Model/PlayerDetection

var damage: int
var floor_position: float
var delay_next_stomp := false


func _ready() -> void:
	_update_model_node()
	_update_show_collisions()
	if not model_node:
		return

	# Get the stomper's current position as the floor pos
	floor_position = model_node.position.y
	
	if not Engine.is_editor_hint():
		damage = Util.get_hazard_damage() + base_damage
		
		# Start the model_node in the raised position
		model_node.position.y = raise_height
		
		if not only_stomp_when_called:
			loop_stomp()
		
		if player_detection:
			player_detection.body_entered.connect(body_entered)
			player_detection.set_collision_mask_value(3, true)
			player_detection.set_collision_mask_value(2, false)
		
		for collision in collisions:
			if collision.get_parent() is StaticBody3D:
				var body : StaticBody3D = collision.get_parent()
				body.set_collision_layer_value(1, false)
				body.set_collision_layer_value(3, true)

func _update_model_node():
	var curr_model: Node3D
	for path in MODEL_PATHS.values():
		if path == model_path:
			curr_model = get_node(path)
			curr_model.show()
		else:
			get_node(path).hide()
	_update_model_scale()
	
func _update_model_scale():
	var curr_model = get_node(model_path)
	model_head = curr_model.find_child('GeometryTransformHelper2')
	model_head.position = head_position
	model_head.scale = head_scale
	
	var coll_pos_ref := DEFAULT_HEAD_POS - head_position
	var coll_pos := Vector3(coll_pos_ref.x, -coll_pos_ref.z, coll_pos_ref.y) * 0.033
	
	head_collision.position = coll_pos
	head_collision.scale = head_scale
	player_detection.position = coll_pos
	model_shaft = curr_model.find_child('shaft')
	var shaft_offset = ((1.0 - head_scale.z) * SHAFT_SIZE)
	model_shaft.position.z = SHAFT_SIZE - shaft_offset
	model_shaft.scale.z = shaft_scale
	shaft_collision_shape.shape.height = (SHAFT_SIZE / 4.0) * shaft_scale
	shaft_collision_shape.position.y = ((shaft_scale - 1.0) * (SHAFT_SIZE * 0.12)) - (shaft_offset / 4.0)
	print(curr_model.find_child('GeometryTransformHelper5').get_aabb().size)

func _update_show_collisions():
	for path in MODEL_PATHS.values():
		for collision: MeshInstance3D in get_node(path).find_children('*_collisions/*', 'MeshInstance3D'):
			collision.visible = show_collisions

func body_entered(body: Node3D) -> void:
	if body is Player:
		player_entered(body)

func player_entered(player: Player) -> void:
	if player.state == Player.PlayerState.WALK:
		await squash_player(player)

func set_collisions_enabled(enable: bool) -> void:
	for shape in collisions:
		shape.set_disabled.call_deferred(not enable)

func tween_step(step: int, tween : Tween) -> void:
	if not player_detection:
		return
	match step:
		2:
			player_detection.set_monitoring.call_deferred(true)
			if delay_next_stomp:
				tween.pause()
				delay_timer.start()
		0:
			player_detection.set_monitoring.call_deferred(false)

func squash_player(player: Player) -> void:
	# Player yelps
	if player.toon.yelp:
		AudioManager.play_sound(player.toon.yelp)
	player.last_damage_source = "a Stomper"
	
	if not only_stomp_when_called:
		delay_next_stomp = true
	
	# Set player to stopped state
	player.state = Player.PlayerState.STOPPED
	
	# Move player to our y pos
	player.global_position.y = global_position.y

	if player.immune_to_crush_damage:
		Util.do_3d_text(player, "Immune!", BattleText.colors.orange[0], BattleText.colors.orange[1])
	else:
		# Damage player
		player.quick_heal(damage)

	# Skip special animations if they're already dead
	if player.stats.hp <= 0:
		return
	
	# Squash them.
	player.set_animation('neutral')
	var base_scale: float = player.toon.scale.y
	var tween := create_tween()
	tween.tween_property(player.toon, 'scale:y', 0.05, 0.05)
	tween.tween_interval(0.5)
	tween.tween_callback(AudioManager.play_sound.bind(SFX_DECOMPRESS))
	tween.tween_callback(player.set_animation.bind('happy'))
	tween.tween_callback(func(): player.animator.speed_scale = 1.5)
	tween.tween_property(player.toon, 'scale:y', base_scale * 1.15, 0.2)
	tween.tween_property(player.toon, 'scale:y', base_scale, 0.05)
	await player.animator.animation_finished
	tween.kill()
	player.animator.speed_scale = 1.0
	player.state = Player.PlayerState.WALK
	player.do_invincibility_frames()

func play_sfx(sfx: AudioStream) -> void:
	sfx_player.set_stream(sfx)
	sfx_player.play()

func loop_stomp() -> void:
	var stomp_tween := do_stomp()
	stomp_tween.set_loops()
	
	# If stomped, wait for 2 cycles before continuing.
	delay_timer.wait_time = (raise_time + STOMP_TIME) * 2.0
	delay_timer.timeout.connect(delay_timeout.bind(stomp_tween))
	
	stomp_tween.step_finished.connect(tween_step.bind(stomp_tween))
	if not is_equal_approx(raise_time_offset, 0.0):
		stomp_tween.custom_step(raise_time_offset)

func do_stomp() -> Tween:
	var stomp_tween := create_tween()
	if only_stomp_when_called:
		stomp_tween.tween_callback(player_detection.set_monitoring.bind(true))
	stomp_tween.tween_property(model_node, 'position:y', floor_position, STOMP_TIME)
	stomp_tween.tween_callback(play_sfx.bind(stomp_sfx))
	if only_stomp_when_called:
		stomp_tween.tween_callback(player_detection.set_monitoring.bind(false))
	stomp_tween.tween_property(model_node, 'position:y', raise_height, raise_time)
	return stomp_tween

func connect_button(button: CogButton) -> void:
	button.s_pressed.connect(func(_button: CogButton):
		var stomp_tween := do_stomp()
		stomp_tween.finished.connect(button.retract)
	)

func delay_timeout(tween: Tween) -> void:
	delay_next_stomp = false
	tween.play()
