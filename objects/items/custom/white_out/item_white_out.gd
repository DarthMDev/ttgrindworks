extends ItemScriptActive

const TRANSITION := preload("res://objects/items/custom/white_out/white_out_transition.tscn")

func use() -> void:
	if not is_instance_valid(Util.floor_manager):
		cancel_use()
		return
	
	get_tree().get_root().add_child(TRANSITION.instantiate())
	Util.get_player().state = Player.PlayerState.STOPPED
	Util.get_player().set_animation('neutral')
	
	attempt_disconnect()
	Util.get_player().stats.current_active_item = null
