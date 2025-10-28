@tool
extends Object
class_name RandomService
## Deprecated random generator
## Has compatibility functions to support the old methods

static func randi_channel(channel_name: String) -> int:
	return RNG.channel(channel_name).randi()

static func randi_range_channel(channel_name: String, from: int, to: int) -> int:
	return RNG.channel(channel_name).randi_range(from, to)

static func randf_channel(channel_name: String) -> float:
	return RNG.channel(channel_name).randf()

static func randf_range_channel(channel_name: String, from: float, to: float) -> float:
	return RNG.channel(channel_name).randf_range(from, to)

static func array_shuffle_channel(channel_name: String, array: Array) -> void:
	RNG.channel(channel_name).shuffle(array)

static func array_pick_random(channel_name: String, array: Array) -> Variant:
	return RNG.channel(channel_name).pick_random(array)

static func rand_weighted_channel(channel_name: String, weights: PackedFloat32Array) -> int:
	return RNG.channel(channel_name).rand_weighted(weights)
