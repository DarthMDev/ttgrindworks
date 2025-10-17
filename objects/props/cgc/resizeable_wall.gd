@tool
extends Node3D

const TopMat: StandardMaterial3D = preload("res://models/facilities/cgc/materials/slate.tres")
const BrickMat: StandardMaterial3D = preload("res://models/facilities/cgc/materials/stone_wall_scaled.tres")
const OFFSET := 0.5

@export var volume: Vector3 = Vector3.ONE:
	set(x):
		volume = x
		if not is_node_ready():
			await ready
		north.size = Vector2(volume.x, volume.y)
		north.position = Vector3(0, 0, volume.z * OFFSET)
		south.size = Vector2(volume.x, volume.y)
		south.position = Vector3(0, 0, -volume.z * OFFSET)
		east.size = Vector2(volume.z, volume.y)
		east.position = Vector3(volume.x * OFFSET, 0, 0)
		west.size = Vector2(volume.z, volume.y)
		west.position = Vector3(-volume.x * OFFSET, 0, 0)
		top.size = Vector2(volume.x, volume.z)
		top.position = Vector3(0, volume.y, 0)
		coll.position = Vector3(0.0, volume.y * 0.5, 0.0)
		coll.shape.size = volume
@export var want_brick_top := false:
	set(x):
		want_brick_top = x
		if not is_node_ready():
			await ready
		top.set_mat(BrickMat if want_brick_top else TopMat)

@onready var north: Node3D = %North
@onready var south: Node3D = %South
@onready var east: Node3D = %East
@onready var west: Node3D = %West
@onready var top: Node3D = %Top
@onready var coll: CollisionShape3D = %Coll

func _ready() -> void:
	top.set_mat(BrickMat if want_brick_top else TopMat)
