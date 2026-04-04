extends 'res://objects/items/custom/seed_logic/custom_seed_base.gd'


var secret_dna: ToonDNA:
	get: return load("res://objects/items/custom/seed_logic/ooowodna.tres")


func setup() -> void:
	Globals.s_shop_spawned.connect(on_shop_spawned)

func on_shop_spawned(shop: ToonShop) -> void:
	if shop.toon and shop.toon_speaks:
		transform_toon(shop.toon)

func transform_toon(toon: Toon) -> void:
	toon.construct_toon(secret_dna)
	toon.set_animation('neutral')
