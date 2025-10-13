extends Node3D

## Funny script that's necessary for this item to work
## Also before you ask, no it cannot use an item script

const ROLL_STATS: Array[String] = ['damage', 'defense', 'evasiveness', 'luck', 'speed']
const GOOD_STATS_RANGE := Vector2(0.05, 0.12)
const BAD_STATS_RANGE := Vector2(-0.08, -0.03)

func setup(item: Item) -> void:
	if item.stats_add.is_empty():
		roll_for_stats(item)
	# Fake evergreen corrector
	ItemService.seen_item(load("res://objects/items/resources/accessories/glasses/masquerade_mask.tres"))

func roll_for_stats(item: Item) -> void:
	var stats_order := ROLL_STATS.duplicate(true)
	RNG.channel(RNG.ChannelMasqueradeStats).shuffle(stats_order)
	var boosts: Array[float] = []
	for i in 3: boosts.append(RNG.channel(RNG.ChannelMasqueradeStats).randf_range(GOOD_STATS_RANGE.x, GOOD_STATS_RANGE.y))
	for i in 2: boosts.append(RNG.channel(RNG.ChannelMasqueradeStats).randf_range(BAD_STATS_RANGE.x, BAD_STATS_RANGE.y))
	for i in stats_order.size():
		item.stats_add[stats_order[i]] = boosts[i]
