extends Resource
class_name FacilityRoom

## The actual room scene
@export var room: PackedScene
## Room rarity 0.0 - 100.0, with 0.0 as impossible, 100.0 as pretty much guaranteed
@export_range(0.0, 100.0) var rarity_weight := 1.0
