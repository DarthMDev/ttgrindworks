extends TextureRect

## Child References
@onready var accessory_opener := $AccessoryOpener
@onready var transform_mode := $VBoxContainer/TransformType/OptionButton
@onready var slide_x := $VBoxContainer/AxisEditor/Slider
@onready var text_x := $VBoxContainer/AxisEditor/LineEdit
@onready var slide_y := $VBoxContainer/AxisEditor2/Slider
@onready var text_y := $VBoxContainer/AxisEditor2/LineEdit
@onready var slide_z := $VBoxContainer/AxisEditor3/Slider
@onready var text_z := $VBoxContainer/AxisEditor3/LineEdit

## Locals
var toon : Toon
var item : ItemAccessory
var model : Node3D
var placement : AccessoryPlacement
var edit_mode : int:
	get:
		return transform_mode.selected
var clipboard_placement : AccessoryPlacement


func _ready():
	menu_apply_vec3(Vector3(0,0,0))

func open_file() -> void:
	accessory_opener.show()

func load_accessory(path : String) -> void:
	if model:
		model.queue_free()
	
	var accessory : ItemAccessory = load(path)
	
	item = accessory
	model = accessory.model.instantiate()
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	
	placement = get_placement(item)
	
	match item.slot:
		Item.ItemSlot.HAT:
			toon.hat_bone.add_child(model)
		Item.ItemSlot.GLASSES:
			toon.glasses_bone.add_child(model)
		Item.ItemSlot.BACKPACK:
			toon.backpack_bone.add_child(model)
		# Idk just quit if you try an item with no slot I guess :/
		_:
			printerr("no item slot. dying :(")
			get_tree().quit()
	apply_transform()

func get_placement(accessory : ItemAccessory) -> AccessoryPlacement:
	var newplacement = ItemAccessory.get_placement(accessory,toon.toon_dna)
	if not newplacement:
		match accessory.slot:
			Item.ItemSlot.BACKPACK:
				newplacement = AccessoryPlacementBody.new()
				newplacement.body_type = toon.toon_dna.body_type
			_:
				newplacement = AccessoryPlacementHead.new()
				newplacement.species = toon.toon_dna.species
				newplacement.head_index = toon.toon_dna.head_index
		accessory.accessory_placements.append(newplacement)
	return newplacement

## Saves the item to its current path
func save_item() -> void:
	if item:
		ResourceSaver.save(item,item.resource_path)
	else:
		push_warning('No item currently loaded!')

## Applies the placement to the model
func apply_transform() -> void:
	if not placement or not model:
		return
	model.position = placement.position
	model.rotation_degrees = placement.rotation
	model.scale = placement.scale

func menu_apply_vec3(vec3 : Vector3,min_value : float = -1.0,max_value : float = 1.0) -> void:
	slide_x.value = vec3.x
	slide_x.min_value = min_value
	slide_x.max_value = max_value
	text_x.text = str(snapped(vec3.x,.01))
	slide_y.value = vec3.y
	slide_y.min_value = min_value
	slide_y.max_value = max_value
	text_y.text = str(snapped(vec3.y,.01))
	slide_z.value = vec3.z
	slide_z.min_value = min_value
	slide_z.max_value = max_value
	text_z.text = str(snapped(vec3.z,.01))

func change_edit_mode(index : int):
	var temp_placement := false
	if not placement:
		placement = AccessoryPlacement.new()
		temp_placement = true
	match index:
		0:
			menu_apply_vec3(placement.position)
		1:
			menu_apply_vec3(placement.rotation,-180.0,180.0)
		2:
			menu_apply_vec3(placement.scale)
	
	if temp_placement:
		placement = null

func change_placement(value : float, axis : int) -> void:
	if not placement:
		return
	var target : String
	match edit_mode:
		0: target = 'position'
		1: target = 'rotation'
		2: target = 'scale'
	var vec : Vector3 = placement.get(target)
	match axis:
		0: vec.x = value
		1: vec.y = value
		2: vec.z = value
	placement.set(target,vec)
	apply_transform()
	change_edit_mode(edit_mode)

func edit_text(text : String, axis : int) -> void:
	change_placement(float(text),axis)

## Resync with DNA Change
func on_dna_change(_dna : ToonDNA) -> void:
	if item:
		model = item.model.instantiate()
		match item.slot:
			Item.ItemSlot.HAT:
				toon.hat_bone.add_child(model)
			Item.ItemSlot.GLASSES:
				toon.glasses_bone.add_child(model)
			Item.ItemSlot.BACKPACK:
				toon.backpack_bone.add_child(model)
		placement = get_placement(item)
		apply_transform()
		change_edit_mode(edit_mode)


## Copy-Paste handling
func _process(_delta) -> void:
	if Input.is_action_just_pressed('ui_copy') and placement:
		clipboard_placement = placement
	if Input.is_action_just_pressed('ui_paste') and placement and clipboard_placement:
		placement.position = clipboard_placement.position
		placement.rotation = clipboard_placement.rotation
		placement.scale = clipboard_placement.scale
		apply_transform()
		change_edit_mode(edit_mode)
