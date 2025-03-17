@tool
extends BattleNode


const MAX_DYNAMIC_COGS := 4
const COG := preload('res://objects/cog/cog.tscn')

## The amount of Cogs to appear in battle
@export var cog_range := Vector2i(2, 4):
	set(x):
		cog_range = x
		cog_range.x = clamp(cog_range.x, 1, MAX_DYNAMIC_COGS)
		cog_range.y = clamp(cog_range.y, cog_range.x, MAX_DYNAMIC_COGS)
		if not cog_node:
			await ready
		if Engine.is_editor_hint():
			_refresh_cogs()
@export var cog_dist := 0.0:
	set(x):
		cog_dist = x
		if not cog_node:
			await ready
		cog_node.position.z = cog_dist

## Node parent for Cogs
@onready var cog_node : Node3D = %Cogs


func _ready() -> void:
	_refresh_cogs()
	if not Engine.is_editor_hint():
		super()

func _refresh_cogs() -> void:
	var cog_count : int
	if Engine.is_editor_hint():
		cog_count = cog_range.y
	else:
		cog_count = RandomService.randi_range_channel("cog_counts", cog_range.x, cog_range.y)
	
	clear_cogs()
	if Engine.is_editor_hint():
		spawn_cogs(cog_count)
	else:
		spawn_cogs(cog_count)

func spawn_cogs(cog_count := 1) -> void:
	for i in cog_count:
		var cog : Cog = COG.instantiate()
		cog_node.add_child(cog)
		cogs.append(cog)
	
	for cog in cogs:
		cog.global_position = get_cog_position(cog)
		
		cog.set_name("Cog%d" % cogs.find(cog))
		face_battle_center(cog)

func clear_cogs() -> void:
	for cog in cog_node.get_children():
		cog.queue_free()
	cogs.clear()
