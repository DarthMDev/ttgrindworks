extends Node3D

## Funny script that's necessary for this item to work
## This can't meaningfully be an item script

const STAT_DIFF_POS := 0.2
const STAT_DIFF_NEG := -0.15

var _item: Item

func setup(item: Item) -> void:
	_item = item
	if item.stats_add.is_empty():
		roll_for_stats(item)
	# Fake evergreen corrector
	ItemService.seen_item(load("res://objects/items/resources/accessories/hats/bee_hive_hairdo.tres"))

func roll_for_stats(item: Item) -> void:
	if not Util.get_player():
		return

	var potential_tracks: Array[Track] = Util.get_player().character.gag_loadout.loadout.duplicate()
	RNG.channel(RNG.ChannelBeeHiveHairdoStats).shuffle(potential_tracks)

	# Positive
	for i: int in 2:
		var track_choice: Track = RNG.channel(RNG.ChannelBeeHiveHairdoStats).pick_random(potential_tracks)
		item.stats_add["gag_boost:%s" % track_choice.track_name] = STAT_DIFF_POS
		potential_tracks.erase(track_choice)

	# Negative
	for i: int in 2:
		var track_choice: Track = RNG.channel(RNG.ChannelBeeHiveHairdoStats).pick_random(potential_tracks)
		item.stats_add["gag_boost:%s" % track_choice.track_name] = STAT_DIFF_NEG
		potential_tracks.erase(track_choice)

func collect() -> void:
	for boost_name: String in _item.stats_add:
		var track_name: String = boost_name.split("gag_boost:")[1]
		var track: Track = Util.get_player().character.gag_loadout.get_track_of_name(track_name)
		Util.get_player().boost_queue.queue_text("%s %s!" % [track_name, "Up" if _item.stats_add[boost_name] > 0 else "Down"], track.track_color.lerp(Color.WHITE, 0.2))
