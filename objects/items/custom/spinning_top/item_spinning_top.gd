extends ItemScriptActive

const SHUFFLE_STATS: Array[String] = ['damage', 'defense', 'evasiveness', 'luck', 'speed']

func use() -> void:
	var stats: PlayerStats = Util.get_player().stats
	
	# Record our base stats
	var base_stats: Dictionary[String, float] = {}
	for stat in SHUFFLE_STATS:
		if stat in stats.character.base_stats:
			base_stats[stat] = stats.character.base_stats.get(stat)
		elif stats.character.additional_stats.keys().has(stat):
			base_stats[stat] = stats.character.additional_stats[stat]
		else:
			base_stats[stat] = 1.0
	
	# Get our total stats above base
	var stat_total := 0.0
	for stat in SHUFFLE_STATS:
		stat_total += stats.get(stat) - base_stats[stat]
	
	## Allocate these stats to random proportions
	
	# First, for each stat, generate a float from 0.0 -> 1.0
	var stat_rolls: Dictionary[String, float] = {}
	for stat in SHUFFLE_STATS: stat_rolls[stat] = RNG.channel(RNG.ChannelSpinningTop).randf()
	
	# Next, add all of these generated numbers together
	var roll_total := 0.0
	for num in stat_rolls.values():
		roll_total += num
	
	# Now get our proportions
	var stat_proportions: Dictionary[String, float] = {}
	for stat in SHUFFLE_STATS: stat_proportions[stat] = stat_rolls[stat] / roll_total
	
	# Now, apply the new stats
	for stat in SHUFFLE_STATS:
		stats.set(stat, base_stats[stat] + (stat_total * stat_proportions[stat]))
	
	do_movie()

func do_movie() -> void:
	var player := Util.get_player()
	var movie := create_tween()
	movie.tween_callback(player.boost_queue.queue_text.bind("Shuffled!", Color.ORANGE))
	movie.tween_callback(func(): player.state = Player.PlayerState.STOPPED)
	movie.tween_callback(player.set_animation.bind('confused'))
	movie.tween_callback(AudioManager.play_sound.bind(load("res://audio/sfx/toon/avatar_emotion_confused.ogg")))
	movie.tween_interval(3.0)
	movie.tween_callback(func(): player.state = Player.PlayerState.WALK)
	movie.finished.connect(movie.kill)
