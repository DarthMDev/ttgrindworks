@tool
extends Resource
class_name GameCredit


@export var icon : Texture2D
@export var name := "":
	set(x):
		name = x
		resource_name = x
@export var role := ""
@export var label_settings : LabelSettings
