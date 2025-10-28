@tool
extends "res://objects/interactables/molten_bellows/molten_bellows.gd"

@export var pushable: bool = true:
	set(new):
		pushable = new
		await NodeGlobals.until_ready(self)
		$PushableComponent.pushable = new

@export_group('Pushable Directions', 'is_pushable')
@export var is_pushable_right: bool = false:
	set(new):
		is_pushable_right = new
		await NodeGlobals.until_ready(self)
		$PushableComponent.is_pushable_right = new
		
@export var is_pushable_left: bool = false:
	set(new):
		is_pushable_left = new
		await NodeGlobals.until_ready(self)
		$PushableComponent.is_pushable_left = new
		
@export var is_pushable_forward: bool = false:
	set(new):
		is_pushable_forward = new
		await NodeGlobals.until_ready(self)
		$PushableComponent.is_pushable_forward = new
		
@export var is_pushable_backward: bool = false:
	set(new):
		is_pushable_backward = new
		await NodeGlobals.until_ready(self)
		$PushableComponent.is_pushable_backward = new
