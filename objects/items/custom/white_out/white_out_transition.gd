extends Control

const FINAL_LINE_COUNT := 6
const LINE_DRAW_TIME := 0.25
const TEXTURE := preload('res://ui_assets/misc/tileable_brush_stroke.png')
var line_count := 0
var line_ratio := 0.0

var background_fade_time: float: 
	get: return (LINE_DRAW_TIME * FINAL_LINE_COUNT) * 1.25

var line_width: float:
	get: return size.y / (FINAL_LINE_COUNT - 1)

func _ready() -> void:
	var line_tween := create_tween().set_trans(Tween.TRANS_SINE)
	for i in FINAL_LINE_COUNT:
		append_line_draw(line_tween)
	do_fadeout()

func append_line_draw(tween: Tween) -> void:
	tween.tween_property(self, 'line_ratio', 1.0, LINE_DRAW_TIME)
	tween.tween_callback(func(): line_count += 1)
	tween.tween_callback(func(): line_ratio = 0.0)

func _process(_delta) -> void:
	refresh_lines()

func refresh_lines() -> void:
	var y_pos := 0.0
	for i in line_count:
		var line: Control
		if not %Lines.get_node_or_null(str(i)):
			line = create_new_line_element()
			line.set_name(str(i))
			%Lines.add_child(line)
			if i % 2 == 0: 
				line.scale.x *= -1
				line.rotation_degrees = -line.rotation_degrees
		else:
			line = %Lines.get_node(str(i))
		
		var start_pos := Vector2(0.0, y_pos)
		var stopping_point := size.x * 2.0
		var y_stopping_point := y_pos
		if i == line_count - 1:
			stopping_point *= line_ratio
			y_stopping_point += (line_width * line_ratio)
		else:
			y_stopping_point += line_width

		# For alternating side
		if i % 2 == 0:
			start_pos.x = size.x * 1.25
			stopping_point = size.x - stopping_point
		
		line.size.y = line_width
		line.position = start_pos
		line.size.x = absf(stopping_point - start_pos.x)
		y_pos += line_width

func create_new_line_element() -> Control:
	return %Line.duplicate()

func do_fadeout() -> void:
	var fade_tween := create_tween().set_parallel()
	fade_tween.tween_property(%FadeBG, 'self_modulate:a', 1.0, background_fade_time)
	fade_tween.tween_callback(AudioManager.fade_music.bind(-80.0, background_fade_time / 1.25))
	fade_tween.finished.connect(on_fade_over.bind(fade_tween))

func on_fade_over(tween: Tween) -> void:
	tween.kill()
	if Globals.cgc_floor_variant == null:
		GameLoader.load_phase(GameLoader.Phase.GAMEPLAY)
		await GameLoader.wait_for_phase(GameLoader.Phase.GAMEPLAY)
		restart_floor()
	else:
		restart_floor()

func restart_floor() -> void:
	# Clean up the current floor
	clean_current_floor()
	
	# Decrement the floor number
	Util.floor_number -= 1
	
	# Get our new floor variant
	var floor_variant: FloorVariant = RandomService.array_pick_random('white_out_floor', Globals.FLOOR_VARIANTS).duplicate()
	if floor_variant.alt_floor and RandomService.randi_channel('floors') % 10 == 0:
		floor_variant = floor_variant.alt_floor
	floor_variant.randomize_details()
	if is_instance_valid(Util.floor_manager):
		floor_variant.reward = Util.floor_manager.floor_variant.reward
	else:
		floor_variant.reward = null
	
	var game_floor: GameFloor = load("res://scenes/game_floor/game_floor.tscn").instantiate()
	game_floor.floor_variant = floor_variant
	
	SceneLoader.change_scene_to_node(game_floor)
	queue_free()
	AudioManager.set_music_volume(0.0)

func clean_current_floor() -> void:
	var game_floor := Util.floor_manager
	if not is_instance_valid(game_floor): return
	for child in game_floor.get_node('Modifiers').get_children():
		if child is FloorModifier:
			child.clean_up()
