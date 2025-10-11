extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	%PushableTrigger.pushable_entered.connect(_handle_first_fall_detect, CONNECT_ONE_SHOT)
	%PushableTrigger2.pushable_entered.connect(_handle_second_fall_detect, CONNECT_ONE_SHOT)
	
func _handle_first_fall_detect():
	var player := Util.get_player()
	if player.state == Player.PlayerState.PUSH:
		player.stop_pushing()
		%PushableMoltenBellows.pushable = false
		%PushableMoltenBellows.move_to_stack_link_below()

func _handle_second_fall_detect():
	var player := Util.get_player()
	print(player.state)
	if player.state == Player.PlayerState.PUSH:
		player.stop_pushing()
		%PushableMoltenBellows2.pushable = false
		%PushableMoltenBellows2.move_to_stack_link_below()
