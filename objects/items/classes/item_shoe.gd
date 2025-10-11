@tool
extends Item
class_name ItemShoe

enum ShoeType {
	NONE,
	SHOE,
	SHORT_BOOT,
	LONG_BOOT,
}
@export var shoe_type: ShoeType = ShoeType.SHOE
@export var shoe_tex: Texture2D
## Optional, because Long Legs are stupid and have incompatible UVs for long boots
@export var long_leg_tex: Texture2D

func get_model() -> PackedScene:
	match shoe_type:
		ShoeType.SHOE: return load('res://objects/items/resources/accessories/shoes/shoe.tscn')
		ShoeType.SHORT_BOOT: return load('res://objects/items/resources/accessories/shoes/short_boot.tscn')
		ShoeType.LONG_BOOT: return load('res://objects/items/resources/accessories/shoes/long_boot.tscn')
	return

func get_correct_texture(dna: ToonDNA) -> Texture2D:
	if dna.leg_type == ToonDNA.BodyType.LARGE and long_leg_tex:
		return long_leg_tex
	return shoe_tex

func apply_item(player: Player, apply_visuals := true, object: Node3D = null) -> void:
	super(player, apply_visuals, object)
	
	if apply_visuals:
		place_shoes(player.toon)

func place_shoes(toon: Toon) -> void:
	toon.legs.set_shoes(shoe_type as ToonLegs.ShoeType, get_correct_texture(toon.toon_dna))
