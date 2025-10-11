extends Node

var exclude: Array[String] = [
	'Anvil Hat',
	'Anti-Cog Control Hat',
	'Archer Hat',
	'Baseball Cap',
]

func _ready() -> void:
	run()

func run() -> void:

	var all_files: Array[String] = PathLoader.load_filepaths("res://objects/items/resources/accessories/backpacks/", ".tres", true, PackedScene)
	
	for path in all_files:
		var file = load(path)
		if file is ItemAccessory:
			adjust_placements(file, path)


func adjust_placements(item: ItemAccessory, path: String) -> void:
	if item.item_name in exclude:
		return
	for placement: AccessoryPlacement in item.accessory_placements:
		placement.position.z += 2.11
		placement.rotation.y += 180.0
	
	ResourceSaver.save(item, path)
