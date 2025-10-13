extends Node3D

func setup(_item: Item) -> void:
	# Fake evergreen corrector
	# This is needed because the item is "fake evergreen" to store its arbitrary data
	ItemService.seen_item(load("res://objects/items/resources/accessories/backpacks/dragonfly_wings.tres"))
