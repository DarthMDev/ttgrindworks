extends Area3D
class_name WorldItem

@export var item: Item
@export var pool: ItemPool
@export var override_replacement_rolls := false

# Locals
var model: Node3D
var rotation_tween: Tween
var bob_tween: Tween

# Child References
@onready var description_bubble : SpeechBubble = %ItemDescription

# Signals
signal s_collected
signal s_item_assigned
signal s_destroyed


func _ready() -> void:
	if not item:
		roll_for_item()
	spawn_item()
	
	# World items can be either collected or left on the floor
	# Make sure the item get removed in either instance
	s_collected.connect(_remove_item)
	Util.s_floor_ended.connect(_remove_item)
	
	# Await 1 second before monitoring
	await $MonitorTimer.timeout
	monitoring = true

func roll_for_item() -> void:
	item = ItemService.get_random_item(pool, override_replacement_rolls)
	
	if not item:
		printerr("Item pool returned null. Freeing world item instance.")
		queue_free()
		return
	s_item_assigned.emit()

func spawn_item() -> void:
	# Spawn in the model
	model = item.model.instantiate()
	add_child(model)
	
	# Check if the item is evergreen
	if not item.evergreen and not item is ItemActive:
		ItemService.seen_item(item)
	elif item is ItemActive:
		if not item.evergreen:
			ItemService.seen_item(item)
		item = item.duplicate()
	else:
		item = item.duplicate()
	
	# Listen for the item's reroll signal
	item.s_reroll.connect(reroll)
	
	# Scale the item as it's specified
	model.scale *= item.world_scale
	
	# Offset the model position on the y-axis
	model.position.y = item.world_y_offset
	
	# Mark the item as in play
	ItemService.item_created(item)
	
	# Do the fancy little tween
	_tween_model()
	
	# Allow items with custom setups to run those
	if model.has_method('setup'):
		model.setup(item)
	
	# Set up the description bubble
	description_bubble.set_text(get_item_description(item))


const QUALITY_STAR := "res://ui_assets/misc/quality_star.png"
const QUALITY_STAR_UNFILLED := "res://ui_assets/misc/quality_star_unfilled.png"
static func get_item_description(_item : Item) -> String:
	var string := ""
	
	# Start with the item name
	# Color it to the item's shop color
	# Make it 1.2x the font size
	string += "[color=%s]%s\n[/color]" % [_item.shop_category_color.to_html(), _item.item_name]
	
	# Now: Append the star rating
	var qualitoon_as_int : int = (_item.qualitoon as int) + 1
	for i in 5:
		if qualitoon_as_int > i:
			string += "[img=center,center,width=2,height=2]res://ui_assets/misc/quality_star.png[/img]"
		else:
			string += "[img=center,center,width=2,height=2]res://ui_assets/misc/quality_star_unfilled.png[/img]"
	
	# Now simply append the description
	string += "\n%s" % _item.big_description
	
	
	
	return string

func reroll() -> void:
	if model:
		model.queue_free()
	ItemService.item_removed(item)
	var discard_item: Item = item
	var test_item: Item = discard_item
	item = null
	if bob_tween:
		bob_tween.kill()
		rotation_tween.kill()
	while discard_item.item_name == test_item.item_name:
		roll_for_item()
		test_item = item
	spawn_item()

func _tween_model() -> void:
	rotation_tween = create_tween()
	rotation_tween.tween_property(self, 'rotation:y', deg_to_rad(360), 3.0)
	rotation_tween.tween_property(self, 'rotation:y', 0, 0.0)
	rotation_tween.set_loops()
	
	bob_tween = create_tween()
	bob_tween.set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(model, 'position:y', item.world_y_offset + 0.1, 1.5)
	bob_tween.tween_property(model, 'position:y', item.world_y_offset - 0.1, 1.5)
	bob_tween.set_loops()

func body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	var player: Player = body
	
	s_collected.emit()
	
	# Turn of monitoring
	set_deferred('monitoring', false)
	$ReactionArea.set_deferred('monitoring', false)
	body_not_reacting(body)
	
	# Apply the item
	apply_item()
	
	# Show UI
	var ui = load('res://objects/items/ui/item_get_ui/item_get_ui.tscn').instantiate()
	ui.item = item
	get_tree().get_root().add_child(ui)
	
	# Play the item collection sound
	item.play_collection_sound()
	
	if model.has_method('modify'):
		model.modify(ui.model)
	
	if model.has_method('custom_collect'):
		await model.custom_collect()
	else:
		## Default collection animations
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		# Accessory collection
		if item is ItemAccessory:
			var accessory_placement: AccessoryPlacement = ItemAccessory.get_placement(item, Util.get_player().character.dna)
			## Failsafe for if no item placement 
			if not accessory_placement:
				push_warning(item.item_name + " has no AccessoryPlacement specified for this Toon's DNA!")
				tween.kill()
				model.queue_free()
				queue_free()
				return
			bob_tween.kill()
			rotation_tween.kill()
			tween.set_parallel(true)
			tween.tween_property(model, 'position', accessory_placement.position, 1.0)
			tween.tween_property(model, 'scale', accessory_placement.scale, 1.0)
			tween.tween_property(model, 'rotation_degrees', accessory_placement.rotation, 1.0)
			tween.tween_callback(func():
				model.position = accessory_placement.position
				model.scale = accessory_placement.scale
				model.rotation_degrees = accessory_placement.rotation)
		elif item is ItemActive:
			if player.stats.current_active_item:
				var replacement_item := player.stats.current_active_item
				item.apply_item(player, true, model)
				rotation_tween.kill()
				bob_tween.kill()
				swap_item(replacement_item)
				tween.kill()
				return
			else:
				tween.tween_property(model, 'scale', Vector3.ZERO, 1.0)
				item.apply_item(player, true, model)
		# Passive Collection
		else:
			tween.tween_property(model, 'scale', Vector3.ZERO, 1.0)
		await tween.finished
		tween.kill()
	queue_free()

func swap_item(swapped_item : Item) -> void:
	var player := Util.get_player()
	var swap_model : Node3D = swapped_item.model.instantiate()
	var tween_time := 1.0
	add_child(swap_model)
	swap_model.scale *= 0.01
	swap_model.global_position = player.toon.backpack_bone.global_position
	model.reparent(player)
	var model_endpt := player.to_local(player.toon.backpack_bone.global_position)
	
	var swap_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	swap_tween.tween_property(swap_model, 'scale', Vector3.ONE * swapped_item.world_scale, tween_time)
	swap_tween.tween_property(swap_model, 'position', Vector3.ZERO, tween_time)
	swap_tween.tween_property(model, 'scale', Vector3.ZERO, tween_time)
	swap_tween.tween_property(model, 'position', model_endpt, tween_time)
	await swap_tween.finished
	swap_tween.kill()
	
	model.queue_free()
	model = swap_model
	item = swapped_item
	_tween_model()
	Task.delay(2.0).connect(
		func():
			set_monitoring.call_deferred(true)
			$ReactionArea.set_monitoring.call_deferred(true)
			description_bubble.set_text(get_item_description(item))
	)

func apply_item() -> void:
	if not Util.get_player():
		return
	
	var player := Util.get_player()
	
	# Reparent accessories to the player
	# They will get tweened into position after this
	if item is ItemAccessory:
		item.apply_item(player, false, model)
		var bone := ItemAccessory.get_bone(item, player)
		remove_current_item(bone)
		model.reparent(bone)
	elif item is ItemActive:
		pass
	else:
		item.apply_item(Util.get_player(), true, model)

func remove_current_item(bone : BoneAttachment3D):
	# If no accessory is there already, 
	if bone.get_child_count() == 0:
		return
	bone.get_child(0).queue_free()

func body_reacted(body):
	if not body is Player:
		return
	ItemService.item_in_proximity(self)

func body_not_reacting(body):
	if not body is Player:
		return
	ItemService.item_left_proximity(self)

func _remove_item() -> void:
	ItemService.item_removed(item)
	if Util.s_floor_ended.is_connected(_remove_item):
		Util.s_floor_ended.disconnect(_remove_item)

func set_description_visible(show_description : bool) -> void:
	description_bubble.force_hide = not show_description

func reroll_visual() -> void:
	poof()
	reroll()

func poof() -> void:
	var dust_cloud = Globals.DUST_CLOUD.instantiate()
	get_tree().get_root().add_child(dust_cloud)
	dust_cloud.global_position = global_position

func destroy_item() -> void:
	poof()
	if item:
		ItemService.item_removed(item)
	s_destroyed.emit()
	queue_free()
