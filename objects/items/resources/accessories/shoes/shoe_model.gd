extends Node3D

@export var mesh: MeshInstance3D

var texture: Texture2D
var shoe_type: ItemShoe.ShoeType
var item: ItemShoe

func setup(res: ItemShoe) -> void:
	set_texture(res.shoe_tex)
	shoe_type = res.shoe_type
	item = res

func set_texture(tex: Texture2D) -> void:
	texture = tex
	mesh.get_surface_override_material(0).albedo_texture = tex

func modify(ui: Node3D) -> void:
	ui.set_texture(texture)

func custom_collect() -> void:
	poof_self()
	swap_player_shoes()

func poof_self() -> void:
	var poof: Node3D = Globals.DUST_CLOUD.instantiate()
	SceneLoader.current_scene.add_child(poof)
	poof.global_position = self.global_position
	hide()

func swap_player_shoes() -> void:
	# Hide player's feet with dust cloud
	var player := Util.get_player()
	var poof: Node3D = Globals.DUST_CLOUD.instantiate()
	player.toon.legs.add_child(poof)
	poof.global_position = player.toon.legs.feet.global_position
	
	# Swap the shoe model/tex
	player.toon.legs.set_shoes(shoe_type as ToonLegs.ShoeType, item.get_correct_texture(Util.get_player().toon.toon_dna))
