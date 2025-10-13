@tool
extends Node3D

enum ShelfType { Gold, Empty }

@export var Type := ShelfType.Gold:
	set(x):
		if x == ShelfType.Empty:
			$shelf_2/geometry/GoldBarStack.visible = false
			$shelf_2/shadow/goldbar_shadow.visible = false
		else:
			$shelf_2/geometry/GoldBarStack.visible = true
			$shelf_2/shadow/goldbar_shadow.visible = true
		Type = x
