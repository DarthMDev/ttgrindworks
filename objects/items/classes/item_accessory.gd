@tool
extends Item
class_name ItemAccessory


@export var accessory_placements: Array[AccessoryPlacement]

## Returns the correct placement of the accessory based on head and body
static func get_placement(item: ItemAccessory, dna: ToonDNA) -> AccessoryPlacement:
	if item.slot == ItemSlot.BACKPACK:
		for placement in item.accessory_placements:
			if placement is AccessoryPlacementBody and placement.body_type == dna.body_type:
				return placement
	else:
		for placement in item.accessory_placements:
			if placement is AccessoryPlacementHead:
				if placement.species == dna.species and placement.head_index == dna.head_index:
					return placement
	return null

static func get_accessory_node(item: ItemAccessory, toon: Toon) -> Node3D:
	if not is_instance_valid(toon):
		return null
	
	match item.slot:
		ItemSlot.HAT:
			return toon.hat_node
		ItemSlot.GLASSES:
			return toon.glasses_node
		ItemSlot.BACKPACK:
			return toon.backpack_node
	
	return null


func apply_item(player: Player, apply_visuals := true, _object : Node3D = null) -> void:
	super(player)
	
	if not player.is_node_ready():
		await player.ready
	
	if apply_visuals:
		place_accessory(player.toon)

func place_accessory(toon: Toon) -> void:
	var mod := model.instantiate()
	var node := ItemAccessory.get_accessory_node(self, toon)
	for accessory in node.get_children():
		accessory.queue_free()
	node.add_child(mod)
	var placement := ItemAccessory.get_placement(self, toon.toon_dna)
	mod.position = placement.position
	mod.rotation_degrees = placement.rotation
	mod.scale = placement.scale
	if mod.has_method('setup'):
		mod.setup(self)
	if toon.color_overlay_mat:
		toon.color_overlay_mat.apply_to_node(mod)

## Needs to update Player look when discarded
func remove_item(player: Player) -> void:
	super(player)
	player.update_accessories()
