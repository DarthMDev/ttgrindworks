extends Resource
class_name BattleStartMovie

# Not preloaded bc it shouldn't be needed
const FALLBACK_MUSIC := "res://audio/music/encntr_suit_winning_indoor.ogg"

@export var skippable := false
@export var override_music : AudioStream

var battle_node : BattleNode
var camera : Camera3D
var focus_cog : Cog
var cogs : Array[Cog] = []
var override_shaking := false

var movie : Tween


## Run this to start the movie
## Default battle start movie example
func play() -> Tween:
	movie = create_tween()
	movie.tween_callback(battle_node.focus_character.bind(focus_cog))
	movie.tween_callback(focus_cog.speak.bind(focus_cog.dna.battle_phrases[RandomService.randi_channel('true_random') % focus_cog.dna.battle_phrases.size()]))
	
	# Start the battle music
	movie.tween_callback(start_music)
	
	movie.tween_interval(2.0)
	
	return movie

func _skip() -> void:
	if movie and movie.is_running():
		movie.custom_step(1000000.0)
		movie.kill()

func focus_random_cog(dial := "") -> Cog:
	if cogs.size() == 0:
		return null
	var cog := cogs[RandomService.randi_channel('true_random') % cogs.size()]
	battle_node.focus_character(cog, -4.01)
	if not dial == "":
		cog.speak(dial)
	return cog

## Attempts to start music, if correct music cannot be found, returns false.
func start_music(music : AudioStream = null) -> bool:
	# If music is directly specified, use that.
	if music:
		AudioManager.set_music(music)
		return true
	# If there is override music specified in the resource, use that.
	elif override_music:
		AudioManager.set_music(override_music)
		return true
	# If all else fails, try the default battle track for the game floor
	elif Util.floor_manager and Util.floor_manager.floor_rooms.battle_music:
		AudioManager.set_music(Util.floor_manager.floor_rooms.battle_music)
		return true
	# If no track can be specified, use the fallback track
	AudioManager.set_music(load(FALLBACK_MUSIC))
	return false

## It's a resource so it can't tween by default
func create_tween() -> Tween:
	var new_tween := battle_node.create_tween()
	new_tween.finished.connect(func(): new_tween.kill())
	return new_tween

## Runs look at on an object
func face_object_towards(object_from : Node3D, object_to : Node3D) -> void:
	object_from.look_at(object_to.global_position)

func face_character(character_from : Actor, node_to : Node3D) -> void:
	character_from.face_position(node_to.global_position)

## USEFUl UNIVERSAL CUTSCENE FUNCTIONS ## 
func shake_camera(cam : Camera3D, time : float, offset : float, taper := true, x := true, y := true, z := true) -> void:
	var base_pos := cam.global_position
	var shaking := true
	
	var timer := cam.get_tree().create_timer(time)
	
	while shaking and not override_shaking:
		await Util.s_process_frame
		var new_offset : float
		if taper:
			new_offset = offset * timer.time_left/time
		else:
			new_offset = offset
		if x:
			cam.global_position.x = base_pos.x + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if y:
			cam.global_position.y = base_pos.y + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		if z:
			cam.global_position.z = base_pos.z + RandomService.randf_range_channel('true_random', -new_offset,new_offset)
		
		if timer.time_left <= 0 or override_shaking:
			shaking = false
