extends BattleStartMovie
class_name SalesDirectorIntroMovie

var directory: Node3D
var cog: Cog

func play() -> Tween:
	# Get our dependencies
	directory = battle_node.get_parent()
	var player := Util.get_player()
	cog = directory.cog
	
	## MOVIE START
	movie = Sequence.new([
		Func.new(directory.first_cam.make_current),
		Func.new(player.set_global_position.bind(directory.first_pos.global_position)),
		Func.new(player.face_position.bind(directory.second_pos.global_position)),
		Func.new(player.set_animation.bind('walk')),
		Func.new(CameraTransition.from_current.bind(battle_node, directory.second_cam, 4.0)),
		LerpProperty.new(player, ^"global_position", 4.0, directory.second_pos.global_position),
		Func.new(player.set_animation.bind('neutral')),
		Func.new(cog.set_animation.bind('walk')),
		Func.new(cog.speak.bind("Finally, a project.")),
		LerpProperty.new(cog, ^"rotation:y", 1.5, 0.0),
		Func.new(cog.set_animation.bind('neutral')),
		Wait.new(2.0),
		Func.new(battle_node.battle_cam.make_current),
		Func.new(start_music),
	]).as_tween(battle_node)

	return movie

func _skip() -> void:
	if movie and movie.is_running():
		movie.custom_step(1000000.0)
		movie.finished.emit()
		movie.kill()
