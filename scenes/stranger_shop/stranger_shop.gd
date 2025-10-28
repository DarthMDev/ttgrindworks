extends Node3D


const OPENER_LINES := [
	"Let's see what you've got.",
	"If you're buyin' I'm sellin'.",
	"Where did I find this stuff? Don't worry about it.",
	"Take a gander at my commodities.",
	"You'd never believe the stuff they throw away.",
]

const BUY_LINES := [
	"Thanks.",
	"Thaaaaaanks.",
	"Thaaaaaaaaaaaaaaaaaaaaanks.",
	"Dang, that was my favorite.",
	"Use it wisely. Or don’t, not my problem.",
	"Thanks for the pick-me-up.",
	"No take-backsies.",
	"Mmm, tasty...",
	"This one’s special, just for you.",
	"Are you sure—oh, you bought it? Cool.",
	"I’d say it’s on the house, but I’m no liar. Pay up.",
]

const GOODBYE_LINES := [
	"Don't be a stranger.",
	"I'll see you later, but you won't see me.",
	"Pleasure doing business with you.",
	"Thanks for stopping by.",
	"Tell your friends to come around.",
	"Exit's out back.",
]

@onready var stranger: Stranger = %Stranger

var player: Player:
	get: return Util.get_player()


func _ready() -> void:
	AudioManager.set_default_music(load("res://audio/music/AShadeOfGiveOrTake.ogg"))
	if not Util.get_player(): await Util.s_player_assigned
	player.recenter_camera()
	do_intro()
	_prepare_shop()
	SaveFileService.progress_file.times_stranger_seen += 1
	Globals.s_stranger_visited.emit()
	if not SaveFileService.progress_file.stranger_met: stranger.stranger_model.disable_rustle = true

#region Cutscenes
func do_intro() -> void:
	if not SaveFileService.progress_file.stranger_met:
		first_time_intro()
		return
	
	var intro_tween := create_tween()
	intro_tween.tween_callback(
		func():
			get_intro_node('IntroCam').make_current()
			player.state = Player.PlayerState.STOPPED
			player.set_animation('neutral')
			player.global_position = get_intro_node('PlayerStartPos').global_position
			player.face_position(get_intro_node('PlayerEnterPos').global_position)
	)
	intro_tween.tween_interval(2.0)
	intro_tween.tween_callback(%ElevatorEnter.open)
	intro_tween.tween_interval(2.0)
	
	intro_tween.tween_callback(player.set_animation.bind('walk'))
	intro_tween.tween_property(player, 'global_position', get_intro_node('PlayerEnterPos').global_position, 3.0)
	intro_tween.parallel().tween_callback(%ElevatorEnter.close).set_delay(1.0)
	intro_tween.tween_callback(player.set_animation.bind('neutral'))
	
	await intro_tween.finished
	intro_tween.kill()
	
	player.state = Player.PlayerState.WALK
	player.camera.make_current()

func first_time_intro() -> void:
	# If item reactions are on, they screw with this cutscene
	# Let's disable the world item reaction areas :)
	for world_item: WorldItem in world_items:
		world_item.get_node('ReactionArea').set_deferred('monitoring', false)
	
	var headturns: Array[Quaternion] = []
	var headturn_vectors: Array[Vector3] = [
		Vector3(30.0, 60.0, 0.0),
		Vector3(30.0, -60.0, 0.0),
		Vector3(0.0, 0.0, 0.0),
		Vector3(10.0, 25.0, 0.0)
	]
	stranger.override_spy_mode = true
	for vec in headturn_vectors:
		player.toon.head_root.rotation_degrees = vec
		headturns.append(player.toon.head_root.quaternion)
	player.toon.head_root.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	
	var intro := create_tween()
	
	intro.tween_callback(
		func():
			get_intro_node('IntroCam').make_current()
			player.state = Player.PlayerState.STOPPED
			player.global_position = get_intro_node('PlayerStartPos').global_position
			player.face_position(get_intro_node('PlayerEnterPos').global_position)
	)
	intro.tween_interval(2.0)
	intro.tween_callback(%ElevatorEnter.open)
	intro.tween_interval(2.0)
	
	intro.tween_callback(player.set_animation.bind('walk'))
	intro.tween_property(player, 'global_position', get_intro_node('PlayerEnterPos').global_position, 3.0)
	intro.parallel().tween_property(get_intro_node('IntroCam'), 'global_position:z', get_intro_node('PlayerCam').global_position.z, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	intro.parallel().tween_property(get_intro_node('IntroCam'), 'global_position:y', get_intro_node('PlayerCam').global_position.y, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	intro.parallel().tween_property(get_intro_node('IntroCam'), 'global_position:x', get_intro_node('PlayerCam').global_position.x, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(1.5)
	intro.parallel().tween_property(get_intro_node('IntroCam'), 'quaternion', get_intro_node('PlayerCam').quaternion, 1.5).set_trans(Tween.TRANS_QUAD).set_delay(1.5)
	intro.parallel().tween_callback(%ElevatorEnter.close).set_delay(2.0)
	
	# Walk in while lookin around
	intro.tween_callback(player.face_position.bind(get_intro_node('PlayerWalkToPos').global_position))
	intro.tween_callback(get_intro_node('PlayerCam').make_current)
	intro.tween_callback(player.toon.set_mouth.bind(Toon.Emotion.SURPRISE))
	intro.tween_property(player, 'global_position', get_intro_node('PlayerWalkToPos').global_position, 5.0)
	intro.set_trans(Tween.TRANS_QUAD)
	intro.parallel().tween_property(player.toon.head_root, 'quaternion', headturns[0], 0.3)
	intro.parallel().tween_property(player.toon.head_root, 'quaternion', headturns[1], 0.5).set_delay(1.0)
	intro.parallel().tween_property(player.toon.head_root, 'quaternion', headturns[2], 0.4).set_delay(2.0)
	intro.parallel().tween_callback(player.toon.set_emotion.bind(Toon.Emotion.NEUTRAL)).set_delay(2.2)
	intro.parallel().tween_callback(player.toon.set_emotion.bind(Toon.Emotion.SURPRISE)).set_delay(3.0)
	intro.parallel().tween_property(get_intro_node('PlayerCam'), 'global_position', get_intro_node('PlayerCamMovePos').global_position, 3.0).set_trans(Tween.TRANS_LINEAR)
	intro.parallel().tween_property(get_intro_node('PlayerCam'), 'global_transform', get_intro_node('ShopCounterCam').global_transform, 3.0).set_delay(3.0)
	intro.parallel().tween_callback(player.set_animation.bind('neutral')).set_delay(5.01)
	intro.set_trans(Tween.TRANS_LINEAR)
	intro.tween_interval(1.0)
	
	# Toon thinks of committing theft
	intro.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.NEUTRAL))
	intro.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.LAUGH))
	intro.tween_callback(player.face_position.bind(world_items[2].global_position))
	intro.tween_callback(get_intro_node('PlayerItemCam').make_current)
	intro.tween_callback(player.set_animation.bind('think'))
	intro.tween_interval(1.25)
	
	# Strangler scares Toon
	intro.tween_callback(stranger.set_animation.bind('in-idle2'))
	intro.tween_callback(stranger.speak.bind("AY! Paws off the merchandise!"))
	intro.tween_interval(0.25)
	intro.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.SURPRISE))
	intro.tween_callback(player.toon.set_mouth.bind(Toon.Emotion.ANGRY))
	intro.tween_callback(player.set_animation.bind('duck'))
	intro.tween_property(player.toon.head_root, 'quaternion', headturns[3], 0.63)
	intro.tween_callback(player.toon.anim_pause)
	intro.tween_interval(2.0)
	
	# Strangler informs Toon that theft is wrong (happy ending)
	intro.tween_callback(get_intro_node('StrangerCam').make_current)
	intro.tween_callback(stranger.speak.bind("That is, of course, unless you've got the goods...?"))
	intro.tween_callback(stranger.set_stranger_active.bind(true))
	intro.tween_property(get_intro_node('StrangerCam'), 'position:z', -3.0, 3.0)
	intro.parallel().tween_callback(stranger.set_animation.bind('out-grunt')).set_delay(1.375)
	intro.tween_interval(2.0)
	
	# Toon attempts to pay with jellybeans
	var jellybean: Node3D = load('res://objects/items/custom/jellybean/red_jellybean.tscn').instantiate()
	player.toon.right_hand_bone.add_child(jellybean)
	jellybean.scale = Vector3.ONE * 0.001
	jellybean.position = Vector3(-0.082, 0.433, -0.033)
	jellybean.hide()
	jellybean.set_color(jellybean.colors[jellybean.BeanColor.RED])
	
	intro.tween_callback(func():
		var jellybean_scale_tween := create_tween()
		jellybean_scale_tween.tween_interval(1.25)
		jellybean_scale_tween.tween_property(jellybean, 'scale', Vector3.ONE * 0.6, 0.25)
		jellybean_scale_tween.finished.connect(jellybean_scale_tween.kill)
		)
	
	var jellytween := create_tween().set_loops()
	jellytween.tween_property(jellybean, 'rotation_degrees:y', 359.9, 2.0)
	jellytween.tween_callback(jellybean.set_rotation_degrees.bind(Vector3.ZERO))
	
	intro.tween_callback(player.set_global_position.bind(get_intro_node('PlayerShopPos').global_position))
	intro.tween_callback(player.toon.set_eyes.bind(Toon.Emotion.SAD))
	intro.tween_callback(player.toon.set_mouth.bind(Toon.Emotion.DELIGHTED))
	intro.tween_callback(player.toon.head_root.set_rotation.bind(Vector3.ZERO))
	intro.tween_callback(get_intro_node('PlayerBeanCam').make_current)
	intro.tween_callback(player.set_animation.bind('give'))
	intro.tween_interval(1.25)
	intro.tween_callback(jellybean.show)
	intro.tween_callback(player.toon.anim_set_speed.bind(0.25))
	for i in 2:
		intro.tween_interval(1.4)
		intro.tween_callback(func(): player.toon.anim_set_speed(player.animator.speed_scale * -1.0))
	intro.tween_callback(player.toon.anim_set_speed.bind(1.0))
	
	# Strangler politely declines the Toon's generous offer
	intro.tween_callback(get_intro_node('StrangerCam').make_current)
	intro.tween_callback(stranger.speak.bind("[shake rate=40.0 level=15]NO DEAL ! ![/shake] That much sugar ain't good for my pipes."))
	intro.tween_callback(stranger.set_animation.bind('out-murmur'))
	intro.tween_callback(jellytween.kill)
	intro.tween_callback(jellybean.queue_free)
	intro.tween_interval(4.0)
	
	# Strangler tells Toon to come back when they're more awesomer
	intro.tween_callback(player.toon.set_emotion.bind(Toon.Emotion.NEUTRAL))
	intro.tween_callback(player.set_animation.bind('neutral'))
	intro.tween_callback(get_intro_node('StrangerLeaveCam').make_current)
	intro.tween_callback(stranger.speak.bind("Come back when you've got something more interesting to barter with."))
	intro.tween_callback(stranger.set_stranger_active.bind(false))
	intro.tween_property(get_intro_node('StrangerLeaveCam'), 'transform', get_intro_node('StrangerLeaveCamPos').transform, 4.0)
	
	# Finally give the player back their grubby little camera
	intro.tween_callback(CameraTransition.from_current.bind(self, player.camera.camera, 3.0))
	intro.tween_interval(3.0)
	
	await intro.finished
	intro.kill()
	
	stranger.speak(".")
	
	## UNCOMMENT THIS WHEN YOU ARE DONE!!
	SaveFileService.progress_file.stranger_met = true
	
	for world_item: WorldItem in world_items:
		world_item.get_node('ReactionArea').set_deferred('monitoring', true)
	
	player.state = Player.PlayerState.WALK
	stranger.override_spy_mode = false
	stranger.stranger_model.disable_rustle = false

func say_random_buy_line() -> void:
	stranger.speak(BUY_LINES.pick_random())


#endregion

func get_intro_node(node_name: String) -> Node:
	return %WalkInCutscene.get_node(node_name)

func increment_elevator_lights() -> void:
	var floor_num: int = %ElevatorEnter.floor_current + 1
	if floor_num == 6: floor_num = 1
	%ElevatorEnter.floor_current = floor_num
	%ElevatorExit.floor_current = floor_num

#region SHOP REGION
@onready var item_cameras: Array[Node] = %ItemCameras.get_children()
@onready var world_items: Array[Node] = %WorldItems.get_children()
@onready var ui: Control = %StrangerUI

var item_index := -1
var shop_tween: Tween
var free_items: Array[WorldItem] = []

func _prepare_shop() -> void:
	# Completely remove their collision shapes
	for world_item: WorldItem in world_items:
		world_item.get_node('CollisionShape3D').queue_free()

func on_shop_interact() -> void:
	stranger.set_stranger_active(true)
	stranger.stranger_model.animator.animation_finished.connect(on_stranger_intro_finished , CONNECT_ONE_SHOT)
	move_player_to_shop()
	if item_index == -1:
		on_first_shop_interact()
	else:
		focus_item(item_index)

func move_player_to_shop() -> void:
	player.state = Player.PlayerState.STOPPED
	player.set_animation('run')
	await player.move_to(%PlayerShopPos.global_position).finished
	player.face_position(stranger.global_position)
	player.set_animation('neutral')

func on_stranger_intro_finished(_anim) -> void:
	stranger.stranger_model.set_animation('out-idle1')

func on_first_shop_interact() -> void:
	run_stranger_intro()

func get_camera(index: int) -> Camera3D:
	return item_cameras[index]

func get_item(index: int) -> Item:
	if not is_instance_valid(world_items[item_index]):
		return null
	var world_item: WorldItem = world_items[index]
	if world_item:
		return world_item.item
	return null

func set_item_index(index: int) -> void:
	item_index = index
	if index < 0: item_index = 3
	if index > 3: item_index = 0

func focus_item(index: int) -> void:
	set_item_index(index)
	var world_item = world_items[item_index]
	var item: Item = null
	if is_instance_valid(world_item): 
		item = world_item.item
	if item:
		ui.item_focused(item, world_item in free_items)
	else:
		ui.item_focused(null)
	run_item_swap()

func start_shop_tween() -> Tween:
	if shop_tween and shop_tween.is_running():
		shop_tween.kill()
	shop_tween = create_tween()
	return shop_tween

## Runs the first time the Player interacts with Stranger in the scene
func run_stranger_intro() -> void:
	var transition_time := 1.0
	var movie := start_shop_tween()
	movie.tween_callback(CameraTransition.from_current.bind(self, %StrangerCam, transition_time))
	movie.tween_callback(stranger.speak.bind(get_random_opener_line()))
	movie.tween_interval(transition_time + 1.5)
	movie.finished.connect(
		func():
			movie.kill()
			focus_item(0)
	)

func get_random_opener_line() -> String:
	return OPENER_LINES.pick_random()

func run_shop_exit() -> void:
	stranger.speak(GOODBYE_LINES.pick_random())
	if stranger.stranger_model.animator.animation_finished.is_connected(on_stranger_intro_finished):
		stranger.stranger_model.animator.animation_finished.disconnect(on_stranger_intro_finished)
	ui.hide()
	stranger.set_stranger_active(false)
	var transition_time := 1.0
	var movie := start_shop_tween()
	movie.tween_callback(CameraTransition.from_current.bind(player, player.camera.camera, transition_time))
	movie.tween_interval(transition_time)
	movie.finished.connect(
		func():
			player.state = Player.PlayerState.WALK
	)
	

func run_item_swap() -> void:
	var transition_time := 0.6
	var movie := start_shop_tween()
	movie.tween_callback(CameraTransition.from_current.bind(self, get_camera(item_index), transition_time))
	movie.tween_interval(transition_time)
	if not ui.visible:
		movie.finished.connect(
			func():
				ui.show()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		)

func shift_left() -> void:
	focus_item(item_index - 1)

func shift_right() -> void:
	focus_item(item_index + 1)

func grant_item() -> void:
	Globals.s_stranger_bought_item.emit()
	var world_item: WorldItem = world_items[item_index]
	if not world_item in free_items:
		free_items.append(world_item)
		say_random_buy_line()
	if world_item.item is ItemActive and player.stats.current_active_item:
		if player.stats.actives_in_reserve.size() >= player.stats.active_reserve_size:
			ui.item_focused(player.stats.current_active_item, true)
	if world_item:
		world_item.collect(player)

#endregion
