extends Node3D


@onready var entrance_elevator : Elevator = $EntranceElevator
@onready var exit_elevator : Elevator = $ExitElevator
@onready var intro_camera : Camera3D = $ElevatorCam
@onready var walk_pos : Node3D = $PlayerWalkPos

func _ready() -> void:
	intro_camera.make_current()
	var player := Util.get_player()
	player.game_timer_tick = false
	player.global_position = entrance_elevator.player_pos.global_position
	player.toon.rotation_degrees.y = 180.0
	
	play_intro(player)
	
	Globals.s_entered_barrel_room.emit()
	
	clear_quests(player.stats)
	clear_items_in_play(player.stats)

func play_intro(player : Player) -> void:
	var intro_tween := create_tween()
	intro_tween.tween_callback(AudioManager.stop_music.bind(true))
	intro_tween.tween_interval(5.0)
	intro_tween.tween_callback(entrance_elevator.open)
	intro_tween.tween_interval(2.0)
	intro_tween.tween_callback(player.set_animation.bind('walk'))
	intro_tween.tween_property(player,'global_position',walk_pos.global_position,3.0)
	intro_tween.tween_callback(player.set_animation.bind('neutral'))
	intro_tween.parallel().tween_callback(entrance_elevator.close).set_delay(2.0)
	intro_tween.tween_interval(1.5)
	await intro_tween.finished
	intro_tween.kill()
	player.camera.make_current()
	player.state = Player.PlayerState.WALK
	player.game_timer_tick = true

func clear_quests(stats : PlayerStats) -> void:
	for quest : Quest in stats.quests.duplicate():
		if not quest.is_complete():
			stats.quests.erase(quest)

## Attempt to clean out any remaining, unretrievable items
func clear_items_in_play(stats: PlayerStats) -> void:
	var safe_items: Array[Item] = []
	for quest: Quest in stats.quests:
		safe_items.append(quest.item_reward)
	for item in ItemService.items_in_play.duplicate():
		if not item in safe_items:
			ItemService.item_removed(item)
