@tool
extends Node3D

@export var want_shadow: bool = true:
	set(x):
		want_shadow = x
		await NodeGlobals.until_ready(self)
		shadow.visible = want_shadow

@onready var shadow: Node3D = %CBMetalBoxShadow
