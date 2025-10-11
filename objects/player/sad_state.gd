extends "res://objects/player/stopped_state.gd"

func _poke_exit(next: State3D) -> bool:
	if not next.name == 'Stopped' and not player.get_animation() == &'lose':
		set_animation('lose')
	
	# Sad is an un-exitable state
	return false
