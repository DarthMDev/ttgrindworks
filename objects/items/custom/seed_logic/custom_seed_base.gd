extends ItemScript

## Base script for custom seed logic
## Acts as an Item that is added to the player on game start


func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	pass
