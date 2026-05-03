extends Area3D
class_name WorldItem

@export var item: Item:
	set(x):
		item = x
		if item:
			print("item set to: %s" % item.item_name)
		else:
			print("item set to: null")
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
	model = item.get_model().instantiate()
	add_child(model)
	
	# Check if the item is evergreen
	if not item.evergreen and not item is ItemActive:
		ItemService.seen_item(item)
	elif item is ItemActive:
		if not item.evergreen:
			ItemService.seen_item(item)
		item = item.duplicate(true)
	else:
		item = item.duplicate(true)
	
	# Listen for the item's reroll signal
	item.s_reroll.connect(reroll)
	
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
	
	# Do a little grow tween on first item spawn
	model.scale *= 0.01
	var grow_tween := create_tween()
	grow_tween.tween_property(model, 'scale', Vector3.ONE * item.world_scale, 0.25)
	grow_tween.finished.connect(grow_tween.kill)


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
	if swap_tween and swap_tween.is_running():
		swap_tween.kill()
		Task.delay(0.5).connect(
			func():
				set_monitoring_deferred(true)
				$ReactionArea.set_monitoring.call_deferred(true)
		)
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
	rotation_tween.tween_property(model, 'rotation:y', deg_to_rad(360), 3.0)
	rotation_tween.tween_property(model, 'rotation:y', 0, 0.0)
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
	
	if player.state == Player.PlayerState.STOPPED:
		return
	collect(player)

func collect(player: Player) -> void:
	
	s_collected.emit()
	
	# Turn of monitoring
	set_monitoring_deferred(false)
	$ReactionArea.set_deferred('monitoring', false)
	body_not_reacting(player)
	
	# Apply the item
	apply_item()
	
	# Show UI
	if SaveFileService.settings_file.item_popups:
		var ui = load('res://objects/items/ui/item_get_ui/item_get_ui.tscn').instantiate()
		ui.item = item
		get_tree().get_root().add_child(ui)
		if model.has_method('modify'):
			model.modify(ui.model)
	
	# Play the item collection sound
	item.play_collection_sound()
	
	
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
			Util.get_player().toon.color_overlay_mat.apply_to_node(model)
		elif item is ItemActive:
			var needs_swap := false
			if player.stats.current_active_item:
				if player.stats.actives_in_reserve.size() >= player.stats.active_reserve_size:
					needs_swap = true
			if needs_swap:
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

var swap_tween: Tween
func swap_item(swapped_item : Item) -> void:
	if swap_tween and swap_tween.is_running():
		swap_tween.custom_step(100.0)
	if rotation_tween and rotation_tween.is_running():
		rotation_tween.kill()
		bob_tween.kill()
	
	item = swapped_item
	var player := Util.get_player()
	var swap_model : Node3D = swapped_item.get_model().instantiate()
	var tween_time := 1.0
	add_child(swap_model)
	swap_model.scale *= 0.01
	swap_model.global_position = player.toon.backpack_bone.global_position
	model.reparent(player)
	var model_endpt := player.to_local(player.toon.backpack_bone.global_position)
	
	swap_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_parallel()
	var tween_ref: Tween = swap_tween # Just to make sure we don't lose our reference here :)
	swap_tween.tween_property(swap_model, 'scale', Vector3.ONE * swapped_item.world_scale, tween_time)
	swap_tween.tween_property(swap_model, 'position', Vector3.ZERO, tween_time)
	swap_tween.tween_property(model, 'scale', Vector3.ZERO, tween_time)
	swap_tween.tween_property(model, 'position', model_endpt, tween_time)
	
	swap_tween.set_parallel(false)
	swap_tween.tween_callback(
		func():
				if model.tree_exited.is_connected(tween_ref.kill):
					model.tree_exited.disconnect(tween_ref.kill)
				model.queue_free()
				model = swap_model
				description_bubble.set_text(get_item_description(swapped_item))
				_tween_model())
	
	swap_tween.tween_interval(2.0)
	swap_tween.tween_callback(
		func():
			set_monitoring_deferred(true)
			$ReactionArea.set_monitoring.call_deferred(true)
	)
	swap_tween.finished.connect(swap_tween.kill)
	model.tree_exited.connect(swap_tween.kill)
	swap_model.tree_exited.connect(swap_tween.kill)
	Engine.time_scale = 1.0

func apply_item() -> void:
	if not Util.get_player():
		return
	
	var player := Util.get_player()
	
	# Reparent accessories to the player
	# They will get tweened into position after this
	if item is ItemAccessory:
		item.apply_item(player, false, model)
		var bone := ItemAccessory.get_accessory_node(item, player.toon)
		remove_current_item(bone)
		model.reparent(bone)
	elif item is ItemActive:
		pass
	else:
		item.apply_item(Util.get_player(), true, model)

func set_monitoring_deferred(enable: bool) -> void:
	#print("monitoring set to %s" % str(enable))
	set_monitoring.call_deferred(enable)

func remove_current_item(node : Node3D):
	# If no accessory is there already, 
	if node.get_child_count() == 0:
		return
	node.get_child(0).queue_free()

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
