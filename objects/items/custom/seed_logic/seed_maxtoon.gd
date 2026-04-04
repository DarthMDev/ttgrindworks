extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'



func on_collect(_item: Item, _object: Node3D) -> void:
	Util.get_player().stats.max_hp = 1
	Util.get_player().stats.hp = 1
	for stat in ['damage', 'defense', 'evasiveness', 'luck']:
		Util.get_player().stats.set(stat, 0.5)
	Util.get_player().stats.speed = 0.7
