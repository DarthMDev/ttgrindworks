@tool
extends Node3D

@export var emitting := false:
	set(x):
		emitting = x
		for child in get_children():
			child.emitting = x
	get:
		return get_child(0).emitting
