extends Node3D
class_name GameFloor

enum RoomType {
	ENTRANCE,
	OBSTACLE,
	BATTLE,
	CONNECTOR,
	ONE_TIME,
	PRE_FINAL,
	BOSS,
}

const ROOM_REPEAT_DETECTION_SIZE := 3
const ANOMALY_TRACKER := preload("res://objects/general_ui/anomaly_tracker/anomaly_tracker.tscn")
const INTERACTIVE_STREAM_PLAYER := "res://scenes/game_floor/music_controller/facility_music_controller.tscn"

## The Floor Variant to be loaded into.
@export var floor_variant: FloorVariant
## Override for the amount of rooms to generate on the floor.
## -1 will make the room count based on the FloorVariant's value.
@export var room_count: int = -1
## Cog Level Range for the floor.
@export var level_range := Vector2i(1,12)
## Cog Spawning Pool.
@export var cog_pool: CogPool

# Floor generation tracking
## The amount of rooms to have in the Scene Tree at a time.
@export var render_rooms: int = 5
@onready var room_node := $Rooms
var unloaded_rooms: Node3D
var room_order: Array[StoredRoom] = []
var room_index := 0
var floor_rooms: DepartmentFloor
var battle_ratio: float = 0.5
var rooms_remaining: Array[int] = []
var one_time_room_indexes: Array[int] = []
var previous_rooms: Array[FacilityRoom] = []
var interactive_music_player: Node

## Simplified method of storing custom values on the floor
var floor_tags: Dictionary[String, Variant] = {}


class StoredRoom:
	var room: Node3D
	var room_transform: Transform3D
	var room_type: RoomType
# Signals
signal s_floor_ended
signal s_marathon_triggered()

# Misc.
@onready var environment: WorldEnvironment = $WorldEnvironment

var anomalies: Array[FloorModifier] = []

# Debug
var debug_modifiers: Array[Script]
var debug_anomalies: Array[Script]
var debug_floor_variant: FloorVariant

func _init() -> void:
	EngineDebugger.register_message_capture('toonlike', _capture_debug_message)
	EngineDebugger.send_message('toonlike:ready_for', ['game_floor'])

func _ready() -> void:
	floor_variant.load_all()
	unloaded_rooms = Node3D.new()
	Util.floor_manager = self
	# Room count must be an odd number
	if room_count % 2 == 0:
		room_count += 1
	Util.floor_number += 1
	DiscordManager.update_presence()
	generate_floor()
	if SaveFileService.run_file:
		SaveFileService.run_file.floor_choice = null
	if floor_variant.dynamic_music:
		interactive_music_player = load(INTERACTIVE_STREAM_PLAYER).instantiate()
		interactive_music_player.interactive_stream = floor_variant.dynamic_music
		add_child(interactive_music_player)

func add_extra_rooms() -> void:
	# Recalculate the available rooms, ensuring the count is still valid
	if room_count % 2 == 0:
		room_count += 1

	var total_rooms = int((room_count - 2) / 2)
	var total_battles := int(total_rooms * battle_ratio)
	rooms_remaining = [total_battles, total_rooms - total_battles]

	# Check if we need to generate more rooms immediately
	var t := room_index
	while t < room_index + render_rooms / 2 and t < room_count - 1:
		if room_order.size() - 1 <= t:
			add_random_room()
		t += 1
		
func generate_floor() -> void:
	if debug_floor_variant:
		floor_variant = debug_floor_variant
	if not floor_variant:
		push_error("Failed to generate floor: No floor variant specified.")
		return
	
	# Get floor difficulty values from room variant
	# Setting value to anything else will let you debug custom sizes
	if room_count == -1:
		room_count = floor_variant.room_count
		level_range = floor_variant.level_range
		cog_pool = floor_variant.cog_pool
	
	# Queue reward:
	if floor_variant.reward:
		s_floor_ended.connect(func(): floor_variant.reward.apply_item(Util.get_player()))
		if floor_variant.discard_item:
			if not floor_variant.discard_item in ItemService.seen_items:
				ItemService.seen_item(floor_variant.discard_item)
	
	# Set up floor modifiers (debug anomalies set below)
	for modifier in floor_variant.modifiers + debug_modifiers:
		initialize_floor_mod(modifier)

	if Util.floor_number == 0:
		$LocationText.set_text("Ground Floor\n%s" % floor_variant.floor_name)
	else:
		$LocationText.set_text("Floor %d\n%s" % [Util.floor_number, floor_variant.floor_name])
	
	# Some values may be copied over from the floor variant to the floor type
	floor_variant.floor_type = floor_variant.floor_type.duplicate(true)
	if floor_variant.room_pack:
		inject_room_pack(floor_variant.floor_type, floor_variant.room_pack)
	
	# Get the floor room values
	floor_rooms = floor_variant.floor_type
	Util.floor_type = floor_rooms
	# Randomly decide 40% - 60% battle rooms 
	battle_ratio = 0.4 + (0.1 * float(RNG.channel(RNG.ChannelBattleRatio).randi() % 3))
	var total_rooms = int((room_count - 2) / 2)
	var total_battles := int(total_rooms * battle_ratio)
	rooms_remaining = [total_battles, total_rooms - total_battles]

	if floor_rooms.special_rooms and RNG.channel(RNG.ChannelRoomLogic).randf() < get_special_room_chance():
		# 50% chance to add a "special room" to the pool
		var sr_idx := RNG.channel(RNG.ChannelRoomLogic).randi_range(1, floor_rooms.special_rooms.size()) - 1
		print('Adding special room: %s' % floor_rooms.special_rooms[sr_idx].room)
		floor_rooms.one_time_rooms.append(floor_rooms.special_rooms[sr_idx].room)

	# Add 2 rooms to the floor per 1 time room
	# And get a room index to slap that room into
	for i in floor_rooms.one_time_rooms.size():
		room_count += 2
		var rand_room := -1
		while rand_room * 2 in one_time_room_indexes or rand_room == -1:
			rand_room = RNG.channel(RNG.ChannelRoomLogic).randi() % (room_count - 1) / 2
			# Ensure 0 cannot be rolled
			rand_room = maxi(rand_room,1)
		one_time_room_indexes.append(rand_room * 2)
	
	
	var player := Util.get_player()
	if not player:
		player = load("res://objects/player/player.tscn").instantiate()
		SceneLoader.add_persistent_node(player)
	player.s_fell_out_of_world.connect(player_out_of_bounds)
	
	# Setup debug anomalies
	for modifier in debug_anomalies:
		var new_mod := initialize_floor_mod(modifier)
		if new_mod:
			anomalies.append(new_mod)
	
	# Generate random rooms
	for i in render_rooms:
		if i >= room_count:
			break
		add_random_room()
		if i == 0:
			spawn_player(player)
	
	# Start anomaly tracker now that we've gotten all our anomalies
	if not anomalies.is_empty():
		show_anomalies()
	
	if Util.floor_number == 0:
		player.fall_in(true)
		player.game_timer_tick = true
	else:
		player.teleport_in(true)
	if Util.window_focused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set the proper default bg music
	if not floor_rooms.background_music.is_empty():
		AudioManager.set_default_music(load(floor_rooms.background_music[randi() % floor_rooms.background_music.size()]))

func spawn_player(player: Player) -> void:
	var entrance = room_node.get_child(0)
	player.global_position = entrance.get_node('SPAWNPOINT').global_position
	player.state = Player.PlayerState.WALK
	player.camera.make_current()
	player.face_position(entrance.get_node('EXIT').global_position)
	player.recenter_camera(true)

func get_random_connector_room() -> PackedScene:
	return load(floor_rooms.connectors[randi() % floor_rooms.connectors.size()])

func inject_room_pack(dept_floor: DepartmentFloor, room_pack: RoomPack) -> void:
	var room_types: Dictionary[String, String] = {
		'entrances': 'entrance_mode',
		'battle_rooms': 'battle_mode',
		'obstacle_rooms': 'obstacle_mode',
		'connectors': 'connector_mode',
		'pre_final_rooms': 'pre_final_mode',
		'final_rooms': 'final_mode',
		'one_time_rooms': 'one_time_mode',
	}
	for room_type in room_types.keys():
		if room_pack.get(room_types[room_type]) == RoomPack.PackMode.REPLACE:
			dept_floor.set(room_type, room_pack.get(room_type))
		else:
			var rooms: Array = dept_floor.get(room_type)
			rooms.append_array(room_pack.get(room_type))
			dept_floor.set(room_type, rooms)

func add_random_room():
	var index := room_order.size()
	var new_room: PackedScene
	var room_type := RoomType.CONNECTOR
	if index == 0:
		new_room = load(floor_rooms.entrances[RNG.channel(RNG.ChannelRoomLogic).randi() % floor_rooms.entrances.size()])
		room_type = RoomType.ENTRANCE
	elif index in one_time_room_indexes:
		new_room = load(floor_rooms.one_time_rooms[one_time_room_indexes.find(index)])
		room_type = RoomType.ONE_TIME
	elif index < room_count - 1:
		if index % 2 == 0:
			# Roll a random room type based on the remaining rooms
			var room_roll := RNG.channel(RNG.ChannelRemainingRooms).randi() % (rooms_remaining[0] + rooms_remaining[1])
			if room_roll < rooms_remaining[0]:
				new_room = roll_for_room(floor_rooms.battle_rooms, 'battle_rooms')
				rooms_remaining[0] -= 1
				room_type = RoomType.BATTLE
			else:
				new_room = roll_for_room(floor_rooms.obstacle_rooms, 'obstacle_rooms')
				rooms_remaining[1] -= 1
				room_type = RoomType.OBSTACLE
		else:
			new_room = get_random_connector_room()
			room_type = RoomType.CONNECTOR
	else:
		if floor_rooms.pre_final_rooms:
			var pre_final_room: PackedScene = roll_for_room(floor_rooms.pre_final_rooms, 'pre_final_rooms')
			append_room(pre_final_room, RoomType.PRE_FINAL)
			append_room(get_random_connector_room(), RoomType.CONNECTOR)
		new_room = roll_for_room(floor_rooms.final_rooms, 'boss_rooms')
		room_type = RoomType.BOSS
		render_rooms += 1
	append_room(new_room, room_type)

func append_room(room: PackedScene, room_type: RoomType):
	var new_module: Node3D = room.instantiate()
	room_node.add_child(new_module)
	new_module.name = str(room_order.size())
	# For all rooms except the entrance, do some tricky math to attach them 
	if not room_order.is_empty():
		var prev_room = room_order[room_order.size() - 1].room
		var prev_exit = prev_room.get_node('EXIT')
		var new_entrance = new_module.get_node('ENTRANCE')
		
		# Failsafe!
		if not prev_room.is_inside_tree():
			prev_room.reparent(room_node)
		
		# Rotate the new room
		var rot = prev_room.global_rotation.y
		new_module.rotation.y = rot
		new_module.rotation.y += prev_exit.rotation.y + new_entrance.rotation.y
	
		# Get reference info
		var entrance_pos = new_entrance.position
		var entrance_global_pos = new_entrance.global_position
		
		# Place new entrance on previous exit
		new_entrance.global_position = prev_exit.global_position
		
		# Get difference between entrance's old and new positions
		var pos_diff = new_entrance.global_position - entrance_global_pos
		
		# Apply the difference to the new module
		new_module.global_position += pos_diff
		
		# Reset entrance node pos
		new_entrance.position = entrance_pos
		
		# For doorways mostly
		if not new_entrance.visible or not prev_exit.visible:
			new_entrance.hide()
			prev_exit.hide()
	
	# Connect the body entered signal from the room to adjust the room renders
	new_module.get_node('RoomArea').body_entered.connect(body_entered_room.bind(room_order.size()))
	new_module.get_node('RoomArea').collision_mask = Globals.PLAYER_COLLISION_LAYER
	
	# Add a new stored room to the room_order array
	var storage := StoredRoom.new()
	storage.room = new_module
	storage.room_transform = new_module.transform
	storage.room_type = room_type
	room_order.append(storage)

func body_entered_room(body, index: int):
	if body is Player:
		room_index = index
		adjust_view(room_index)

func roll_for_room(rooms: Array[FacilityRoom], seed_channel := RNG.ChannelTrueRandom) -> PackedScene:
	rooms = rooms.duplicate(true)
	for room in previous_rooms:
		if room in rooms:
			rooms.erase(room)
	
	var weights : Array[float] = []
	for room in rooms:
		weights.append(room.rarity_weight)
	
	var room_idx := RNG.channel(seed_channel).rand_weighted(weights)
	if previous_rooms.size() >= ROOM_REPEAT_DETECTION_SIZE:
		previous_rooms.pop_front()
	previous_rooms.append(rooms[room_idx])
	return load(rooms[room_idx].room)

func adjust_view(index: int = 0):
	if room_order.is_empty():
		return
		
	var border := render_rooms / 2
	var lower_bound := maxi(index-border, 0)
	var upper_bound := maxi(index+border, render_rooms)
	
	for i in room_order.size():
		var room = room_order[i].room
		if i < lower_bound or i > upper_bound:
			if room.get_parent() == room_node:
				room.reparent(unloaded_rooms)
		else:
			if not room.is_inside_tree():
				room.reparent(room_node, false)
				room.transform = room_order[i].room_transform
		
	# Check if new rooms are needed
	var t := index
	while t < room_index+render_rooms / 2 and t < room_count - 1:
		if room_order.size() - 1 <= t:
			add_random_room()
		t += 1

func get_current_room() -> Node3D:
	return room_order[room_index].room

func get_current_room_type() -> RoomType:
	var stored_room := room_order[room_index]
	if stored_room.room_type:
		return stored_room.room_type
	return RoomType.CONNECTOR

func _notification(what):
	# Free unloaded rooms when scene is being freed
	if what == NOTIFICATION_PREDELETE:
		unloaded_rooms.queue_free()
		EngineDebugger.unregister_message_capture('toonlike')

func player_out_of_bounds(player : Player) -> void:
	var entrance_node: Node3D
	if get_current_room().has_node('SPAWNPOINT'):
		entrance_node = get_current_room().get_node('SPAWNPOINT')
	else:
		entrance_node = get_current_room().get_node('ENTRANCE')
	player.global_position = entrance_node.global_position
	player.fall_in(true)

func initialize_floor_mod(modifier : Script) -> FloorModifier:
	var new_mod := Node.new()
	new_mod.set_script(modifier)
	if new_mod is FloorModifier:
		$Modifiers.add_child(new_mod)
		new_mod.initialize(self)
		new_mod.set_name(new_mod.get_mod_name())
		if modifier in floor_variant.anomalies:
			anomalies.append(new_mod)
		return new_mod
	return null

func show_anomalies(new_anomalies : Array[FloorModifier] = anomalies) -> void:
	var tracker := ANOMALY_TRACKER.instantiate()
	tracker.anomalies = new_anomalies
	add_child(tracker)
	tracker.play()

func add_anomaly(modifier : Script) -> void:
	var new_mod := initialize_floor_mod(modifier)
	if new_mod:
		anomalies.append(new_mod)
		if not Util.get_player().obscured_anomalies:
			Util.get_player().boost_queue.queue_text(new_mod.get_mod_name(), new_mod.text_color)
	
func spawn_new_anomalies(count : int) -> Array[FloorModifier]:
	var new_anomalies : Array[FloorModifier] = []
	for i in count:
		var new_anomaly := floor_variant.get_new_anomaly()
		if new_anomaly:
			var anomaly_node := initialize_floor_mod(new_anomaly)
			new_anomalies.append(anomaly_node)
			anomalies.append(anomaly_node)
			if not Util.get_player().obscured_anomalies:
				Util.get_player().boost_queue.queue_text(anomaly_node.get_mod_name(), anomaly_node.text_color)
			Util.get_player().stats.stranger_chance += Util.get_player().stats.stranger_chance_per_anomaly
	return new_anomalies

func remove_anomaly(anomaly : FloorModifier) -> void:
	if anomaly in anomalies:
		anomaly.clean_up()
		anomalies.erase(anomaly)
		floor_variant.anomalies.erase(anomaly.get_script())
		anomaly.queue_free()

func get_special_room_chance() -> float:
	var luck := 1.0
	var base_chance := 0.12
	if is_instance_valid(Util.get_player()):
		luck = Util.get_player().stats.luck
	return base_chance + (luck - 1.0)

func _capture_debug_message(message: String, data: Array) -> bool:
	if message == 'game_floor:add_floor_mods':
		var anomalies_list = (
			FloorVariant.ANOMALIES_POSITIVE +
			FloorVariant.ANOMALIES_NEUTRAL +
			FloorVariant.ANOMALIES_NEGATIVE
		)
		for modifier in data:
			if modifier in anomalies_list:
				debug_anomalies.append(load(modifier))
			else:
				debug_modifiers.append(load(modifier))
		return true
	elif message == 'game_floor:set_floor_variant':
		debug_floor_variant = load(data[0])
	return false

#region GAME TRACKING
## Game Signals
signal s_cog_spawned(cog: Cog)
#endregion
