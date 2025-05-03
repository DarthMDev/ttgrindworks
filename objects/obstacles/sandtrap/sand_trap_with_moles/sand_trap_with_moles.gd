@tool
extends ObstacleSandTrap

const SAND_MOLE := preload('res://objects/obstacles/sandtrap/sand_trap_with_moles/sand_mole/sand_mole.tscn')

@onready var mole_node : Node3D = %Moles

@export var mole_count_range := Vector2i(3, 5)

var mole_count := 1


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		initialize_moles()

func initialize_moles() -> void:
	mole_count = RandomService.randi_range_channel('sand_trap_moles', mole_count_range.x, mole_count_range.y)
	
	for i in mole_count:
		var mole := SAND_MOLE.instantiate()
		mole.bounding_start = -(size / 2.0) * AREA_SIZE
		mole.bounding_end = -mole.bounding_start
		mole_node.add_child(mole)
