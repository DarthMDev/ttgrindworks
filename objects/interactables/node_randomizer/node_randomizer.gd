extends Node
class_name NodeRandomizer


## Expandable script for removing some boilerplate from development


enum ChanceType {
	## Removes all targets
	REMOVE,
	## Removes all but one target
	REMOVE_MOST,
	## Rolls for each target individually
	REMOVE_RANDOM,
	## Just emits the signal
	EMIT_SIGNAL,
	## Removes a singular random node
	REMOVE_SINGULAR_RANDOM,
}

@export var chance_type := ChanceType.REMOVE
@export_range(0.001, 1.0, 0.001) var chance := 0.5
@export var random_channel := RNG.ChannelTrueRandom
@export var targets: Array[Node] = []

signal s_chance_success


func _ready() -> void:
	if RNG.channel(random_channel).randf() < chance:
		do_the_thing()
	match chance_type:
		ChanceType.REMOVE_RANDOM: free_random(targets)
		ChanceType.REMOVE_SINGULAR_RANDOM: free_random([RNG.channel(random_channel).pick_random(targets)])

func do_the_thing() -> void:
	match chance_type:
		ChanceType.REMOVE: free_nodes(targets)
		ChanceType.REMOVE_MOST: free_most(targets)
	s_chance_success.emit()

func free_nodes(nodes: Array[Node]) -> void:
	for node in nodes: node.queue_free()

func free_most(nodes: Array[Node]) -> void:
	var winner: Node = RNG.channel(random_channel).pick_random(nodes)
	for node in nodes:
		if not node == winner: node.queue_free()

func free_random(nodes: Array[Node]) -> void:
	for node in nodes:
		if RNG.channel(random_channel).randf() < chance:
			node.queue_free()
