@tool
extends StatusEffect

@export var banned_color := Color.DARK_RED

@export var gags: Array[ToonAttack]

signal s_banned_gag_used

# Dictionary format: GagButton : Tween
# Makes referencing these a bit easier for when stuff gets weird (goggles)
var tween_storage := {}
var gag_not_used = false
# Ref to battle ui's gag tracks
var track_elements: Array[TrackElement]:
	get: 
		var arr: Array[TrackElement] = []
		arr.assign(manager.battle_ui.gag_tracks.get_children())
		return arr

func apply() -> void:
	for element in track_elements:
		element.s_refreshing.connect(track_refreshed)
	manager.s_round_started.connect(round_started)

func track_refreshed(track_element: TrackElement) -> void:
	await Util.s_process_frame
	reset_track_tweens(track_element)

## Returns the buttons CURRENTLY assigned to the banned gags
func get_track_buttons(track_element: TrackElement) -> Array[GagButton]:
	var buttons: Array[GagButton] = []
	for gag in track_element.gags:
		for banned_gag in gags:
			if banned_gag.action_name == gag.action_name:
				buttons.append(track_element.gag_buttons[track_element.gags.find(gag)])
	return buttons 

func round_started(actions: Array[BattleAction]) -> void:
	clear_tweens()
	for action in actions:
		for gag in gags:
			if gag.action_name == action.action_name:
				s_banned_gag_used.emit(action)

func clear_tweens() -> void:
	for element in track_elements:
		clear_track_tweens(element)

func reset_track_tweens(track_element: TrackElement) -> void:
	clear_track_tweens(track_element)
	start_track_tweens(track_element)

func clear_track_tweens(track_element: TrackElement) -> void:
	for button: GagButton in track_element.gag_buttons:
		if button in tween_storage:
			tween_storage[button].kill()
			tween_storage.erase(button)
			if button.disabled:
				button.self_modulate = button.DISABLED_COLOR
			else:
				button.self_modulate = button.default_color

func start_track_tweens(track_element: TrackElement) -> void:
	for button in get_track_buttons(track_element):
		if not button.disabled:
			tween_storage[button] = create_tween(button)

func expire() -> void:
	if not is_instance_valid(target) or target.stats.hp <= 0:
		return
	

func cleanup() -> void:
	clear_tweens()
	#("running cleaning up on ban toon / 3n")
	for element in track_elements:
		if element.s_refreshing.is_connected(track_refreshed):
			element.s_refreshing.disconnect(track_refreshed)

	if manager.s_round_started.is_connected(round_started):
		manager.s_round_started.disconnect(round_started)

func create_tween(button: GagButton) -> Tween:
	var standard_color := button.self_modulate
	var tween := manager.create_tween().set_loops()
	tween.tween_property(button, 'self_modulate', banned_color, 1.0)
	tween.tween_property(button, 'self_modulate', standard_color, 1.0)
	return tween

func is_banned_gag_used(actions : Array[BattleAction]) -> bool:
	for action in actions:
		for gag in gags:
			if gag.action_name == action.action_name:
				return true
	return false
