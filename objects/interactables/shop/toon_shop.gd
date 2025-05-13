extends Node3D
class_name ToonShop

const SHOP_SALE_MULT := 0.5
const SOLD_OUT_PHRASES: Array[String] = [
	"Fresh out of stock, sorry pal.",
	"I've got nothing else to sell you. Try again later.",
]

@export var toon: Toon
@export var toon_speaks := true

@onready var world_items := $Items.get_children()
@onready var cam_positions := $CamPositions
@onready var ui := $ShopUI

var item_index := 0

var stored_prices: Dictionary = {}
var discounted_items: Dictionary = {}


func _ready() -> void:
	# Animate toon
	if toon:
		var dna := ToonDNA.new()
		dna.randomize_dna()
		toon.construct_toon(dna)
		toon.set_animation('neutral')
	
	# And completely remove their collision shapes
	for world_item: WorldItem in world_items:
		world_item.get_node('CollisionShape3D').queue_free()
		if not Util.get_player():
			await Util.s_player_assigned
		if Util.get_player().less_shop_items and world_items.find(world_item) in [1, 2]:
			world_item.queue_free()
	
	# Do this separately so that shops with less items (i.e. dragon wings)
	# won't bug out w/ discounts
	for i: int in world_items.size():
		discounted_items[i] = false
		stored_prices[i] = 0

	for world_item: WorldItem in world_items:
		if (not world_item) or (not is_instance_valid(world_item)) or world_item.is_queued_for_deletion():
			continue
		if world_item.item == null:
			await world_item.s_item_assigned

		stored_prices[world_items.find(world_item)] = get_price(world_item)

## React to player interact
func body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	
	if is_shop_empty():
		cancel_shop_enter()
		return
	
	# Free the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Stop the player
	var player: Player = body
	player.state = Player.PlayerState.STOPPED
	player.set_animation('neutral')
	player.global_position.y = global_position.y
	if toon:
		player.face_position(toon.global_position)
		if toon_speaks:
			toon.speak("Choose what you want to buy.")

	select_item(item_index, false)
	
	# Await camera movement
	await CameraTransition.from_current(self, get_camera(item_index), 1.0).s_done
	
	# Activate ui
	ui.show()

## Returns the transform for a particular item 
func get_camera(index: int) -> Camera3D:
	return cam_positions.get_child(index)

func select_item(index: int, move_cam := true) -> void:
	item_index = index
	var item: Item = get_item(index)
	ui.set_item(item, stored_prices[index], discounted_items[item_index])
	if move_cam:
		CameraTransition.from_current(self, get_camera(index), 0.6)

func get_price(world_item: WorldItem) -> int:
	var item: Item = world_item.item
	if not item:
		return -1
	var base_price: float
	if item.custom_shop_price != 0:
		base_price = item.custom_shop_price
	else:
		base_price = 2.0 + float(item.qualitoon as int + 1) * 7.0
	var mult: float = RandomService.randf_range_channel('shop_item_random', 0.9, 1.1)
	base_price = max(0, (base_price * mult) - Util.get_player().stats.shop_discount)
	var price_with_discount := base_price
	# 20% chance of discount per 1.0 luck stat
	if RandomService.randf_channel('shop_item_random') < Util.get_player().stats.get_stat('luck') * 0.2:
		price_with_discount *= SHOP_SALE_MULT
		discounted_items[world_items.find(world_item)] = true
	price_with_discount *= get_inflation_rate()
	return maxi(0, roundi(price_with_discount))

func get_inflation_rate() -> float:
	if not is_instance_valid(Util.floor_manager):
		return 1.0
	var game_floor : GameFloor = Util.floor_manager
	if game_floor.floor_tags.has('shop_inflation'):
		return game_floor.floor_tags['shop_inflation']
	return 1.0

func move_selection(dir: int) -> void:
	item_index += dir
	if item_index >= world_items.size():
		item_index = 0
	elif item_index < 0:
		item_index = world_items.size() - 1
	select_item(item_index)

func get_item(index: int) -> Item:
	if not is_instance_valid(world_items[index]) or not world_items[index].monitorable:
		return null
	else:
		return world_items[index].item

func purchase() -> void:
	Util.get_player().stats.money -= stored_prices[item_index]
	world_items[item_index].monitorable = false
	if Util.get_player().stats.current_active_item and world_items[item_index].item is ItemActive:
		yeah_ill_hold_that_for_you()
	ui.set_item(null, -1)
	world_items[item_index].body_entered(Util.get_player())
	if toon and toon_speaks:
		toon.speak("It's all yours. Enjoy!")

## Yeah they'll hold it for you
func yeah_ill_hold_that_for_you() -> void:
	var current_index := item_index
	await Task.delay(5.0)
	world_items[current_index].monitorable = true
	stored_prices[current_index] = 0

func is_shop_empty() -> bool:
	for item in world_items:
		if is_instance_valid(item):
			return false
	return true

func cancel_shop_enter() -> void:
	if toon_speaks:
		toon.speak(RandomService.array_pick_random('true_random', SOLD_OUT_PHRASES))

func exit() -> void:
	ui.hide()
	if toon and toon_speaks:
		toon.speak("Thanks for stopping by!")
	await CameraTransition.from_current(self, Util.get_player().camera.camera, 1.0).s_done
	Util.get_player().state = Player.PlayerState.WALK
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
