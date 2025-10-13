extends ItemScriptActive

const TRANSITION := preload("res://objects/items/custom/white_out/white_out_transition.tscn")

func validate_use() -> bool:
	return is_instance_valid(Util.floor_manager)

func use() -> void:
	
	get_tree().get_root().add_child(TRANSITION.instantiate())
	Util.get_player().state = Player.PlayerState.STOPPED
	Util.get_player().set_animation('neutral')
