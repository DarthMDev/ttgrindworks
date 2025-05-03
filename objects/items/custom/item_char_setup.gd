extends ItemScript
class_name ItemCharSetup


## Override this for character setup
## Runs just before the Cog Building
## Also runs just before the ground floor begins
func first_time_setup(_player : Player) -> void:
	pass


## You shouldn't need to override this
func on_collect(_item : Item, _object : Node3D) -> void:
	if not is_instance_valid(Util.get_player()):
		await Util.s_player_assigned
	var player := Util.get_player()
	first_time_setup(player)
	player.stats.start_stat_monitors()
