extends ItemCharSetup

const MIN_HP := 25
const MAX_HP := 35

func first_time_setup(player : Player) -> void:
	if player.stats.character.starting_items.size() == 1:
		randomize_stats(player)
	else:
		randomize_gags(player)

func randomize_stats(player : Player) -> void:
	# Randomize stats
	var random_stats: Array[String] = [
		'damage', 'defense', 'evasiveness', 'luck', 'speed'
	]
	
	# Random HP
	player.stats.max_hp = RandomService.randi_range_channel('true_random', MIN_HP, MAX_HP)
	player.stats.hp = player.stats.max_hp
	player.character.starting_laff = player.stats.max_hp
	var avg_hp := (MAX_HP + MIN_HP) / 2
	var point_boost := avg_hp - player.stats.max_hp
	
	# Randomize stats
	var good_points := 20
	var bad_points := 12
	var point_cost := 0.02
	if signi(point_boost) == 1: good_points += point_boost
	else: bad_points += absi(point_boost)
	while good_points > 0:
		var stat := random_stats[RandomService.randi_channel('random_stat_rolls') % random_stats.size()]
		player.stats.set(stat, player.stats.get(stat) + point_cost)
		good_points -= 1
	while bad_points > 0:
		var stat := random_stats[RandomService.randi_channel('random_stat_rolls') % random_stats.size()]
		player.stats.set(stat, player.stats.get(stat) - point_cost)
		bad_points -= 1
	print('stat randomization done :D')
	Util.random_stats = player.stats
	
	var item_pools: Array[ItemPool] = [load('res://objects/items/pools/accessories.tres'), load('res://objects/items/pools/active_items.tres')]
	for pool in item_pools:
		var item : Item = ItemService.get_random_item(pool, true)
		player.stats.character.starting_items.append(item)
		if item is ItemActive:
			player.stats.current_active_item = item.duplicate()

func randomize_gags(player : Player) -> void:
	# Get one random offense and one random support track
	var character : PlayerCharacter = player.stats.character
	var offense_tracks: Array[Track] = []
	var support_tracks: Array[Track] = []
	var selected_tracks: Array[Track] = []
	var gag_loadout := character.gag_loadout
	
	for track in gag_loadout.loadout:
		if track.track_type == Track.TrackType.OFFENSE:
			offense_tracks.append(track)
		else:
			support_tracks.append(track)
	# Choose two random tracks if either support or offense is empty
	# Probably won't ever run but yk
	if offense_tracks.is_empty() or support_tracks.is_empty():
		var selected_track: Track
		while selected_tracks.size() < 2 or not selected_track in selected_tracks:
			selected_track = gag_loadout.loadout[RandomService.randi_channel('true_random') % gag_loadout.loadout.size()]
			if not selected_track in selected_tracks: selected_tracks.append(selected_track)
	# Otherwise run like normal
	else:
		selected_tracks.append(offense_tracks[RandomService.randi_channel('true_random') % offense_tracks.size()])
		selected_tracks.append(support_tracks[RandomService.randi_channel('true_random') % support_tracks.size()])
	
	# Start player off with anywhere from level 1-3 gags
	for track in selected_tracks:
		player.stats.gags_unlocked[track.track_name] += RandomService.randi_channel('true_random') % 2 + 1
	
	var random_stats: Array[String] = [
		'damage', 'defense', 'evasiveness', 'luck', 'speed'
	]
	# Restore stats
	if Util.random_stats:
		for stat in random_stats:
			player.stats.set(stat, Util.random_stats.get(stat))
