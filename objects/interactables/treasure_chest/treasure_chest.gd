@tool
extends Node3D
class_name TreasureChest

var REWARD_OVERRIDE_CHANCE := 0.25
var WORLD_ITEM: PackedScene
var SFX_OPEN: AudioStreamOggVorbis

@export var override_replacement_rolls := false
@export var override_item: Item
@export var unopenable := false

@export var item_pool: ItemPool:
	set(x):
		item_pool = x
		if not is_node_ready():
			await ready
		if texture_lock: return
		update_texture(get_chest_tex())
		set_ray_gradient(get_ray_gradient())

@export var scripted_progression := false
@export var ray_gradient : Gradient
## Enabling locks the changing of item pool to impact chest texture and ray gradient
@export var texture_lock := false

@onready var chest : Node3D = %Chest
@onready var light_ray : MeshInstance3D = $Chest/Lightray


## For texture swap
const SPECIAL_TEXTURE := preload("res://models/props/treasure_chest/RewardChest.png")
const BOSS_TEXTURE := preload("res://models/props/treasure_chest/TreasureChestSpecial.png")
const DOODLE_TEXTURE := preload("res://models/props/treasure_chest/TreasureChestBronzeDirt.png")
const GOLD_TEXTURE := preload("res://models/props/treasure_chest/TreasureChestGold.png")
const SILVER_TEXTURE := preload("res://models/props/treasure_chest/TreasureChestSilver.png")
const BRONZE_TEXTURE := preload("res://models/props/treasure_chest/TreasureChestBronze.png")
var POOL_TEXTURES : Dictionary[String, Texture2D] = {
	"res://objects/items/pools/special_items.tres" : SPECIAL_TEXTURE,
	"res://objects/items/pools/rewards.tres" : GOLD_TEXTURE,
	"res://objects/items/pools/progressives.tres" : SILVER_TEXTURE,
	"res://objects/items/pools/battle_clears.tres" : BRONZE_TEXTURE,
	"res://objects/items/pools/doodle_treasure.tres" : DOODLE_TEXTURE,
	"default" : GOLD_TEXTURE
}

var POOL_GRADIENTS : Dictionary[String, String] = {
	"res://objects/items/pools/rewards.tres" : "res://models/props/treasure_chest/sunrays/goldchest_sunrays.tres",
	"res://objects/items/pools/battle_clears.tres" : "res://models/props/treasure_chest/sunrays/bronzechest_sunrays.tres",
	"res://objects/items/pools/progressives.tres" : "res://models/props/treasure_chest/sunrays/silverchest_sunrays.tres",
	"res://objects/items/pools/doodle_treasure.tres" : "res://models/props/treasure_chest/sunrays/doodlechest_sunrays.tres",
	"res://objects/items/pools/special_items.tres" : "res://models/props/treasure_chest/sunrays/specialchest_sunrays.tres",
	"default" : "res://models/props/treasure_chest/sunrays/goldchest_sunrays.tres"
}

const EXTRA_TURN := preload(ExtraTurnItem.BASE_ITEM)
const POINT_BOOST := preload(PointBoostItem.BASE_ITEM)
var LAFF_BOOST := load("res://objects/items/resources/passive/laff_boost.tres")
var SCRIPTED_PROGRESSION_ITEMS: Dictionary = {
	0: null,
	1: EXTRA_TURN,
	2: POINT_BOOST,
	3: null,
	4: EXTRA_TURN,
	5: LAFF_BOOST,
}

var opened := false
var material_duped := false
var ray_tex : GradientTexture2D

signal s_opened

func _init():
	if Engine.is_editor_hint():
		return
	
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'WORLD_ITEM': 'res://objects/items/world_item/world_item.tscn',
		'SFX_OPEN': 'res://audio/sfx/misc/diving_treasure_pick_up.ogg',
	})

func body_entered(body: Node3D) -> void:
	if unopenable:
		return
	if not body is Player or opened:
		return
	elif body is Player and body.state == Player.PlayerState.STOPPED:
		return
	open()
	opened = true

func open():
	AudioManager.play_sound(SFX_OPEN)
	$AnimationPlayer.play('open')
	var item: WorldItem = WORLD_ITEM.instantiate()
	item.override_replacement_rolls = override_replacement_rolls
	assign_item(item)
	$Item.add_child(item)
	s_opened.emit()
	light_ray.show()
	item.s_collected.connect(kill_the_lights, CONNECT_ONE_SHOT)
	item.s_destroyed.connect(kill_the_lights)

func kill_the_lights() -> void:
	var shader : ShaderMaterial = light_ray.get_surface_override_material(0)
	var light_tween := create_tween().set_trans(Tween.TRANS_QUAD)
	light_tween.tween_method(set_light_level.bind(shader), 1.0, 0.0, 1.0)
	light_tween.finished.connect(light_tween.kill)

func set_light_level(level : float, shader : ShaderMaterial) -> void:
	shader.set_shader_parameter('strength', level)

func assign_item(world_item: WorldItem):
	if scripted_progression and SCRIPTED_PROGRESSION_ITEMS[Util.floor_number] != null:
		var scripted_item = SCRIPTED_PROGRESSION_ITEMS[Util.floor_number]
		# 5th floor has a +8 laff boost
		if scripted_item == LAFF_BOOST:
			scripted_item = scripted_item.duplicate()
			scripted_item.stats_add['max_hp'] = 8
			scripted_item.stats_add['hp'] = 8
		world_item.item = scripted_item
		return
	if override_item:
		world_item.item = override_item
		return
	world_item.pool = item_pool

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if not item_pool:
		do_reroll_chance()
	elif item_pool.resource_path == "res://objects/items/pools/special_items.tres":
		override_replacement_rolls = true
	
	Globals.s_chest_spawned.emit(self)

func do_reroll_chance() -> void:
	var reward_chest_roll := RandomService.randf_channel('chest_rolls')
	if reward_chest_roll < Globals.reward_chest_chance:
		print("Spawning reward pool chest")
		item_pool = ItemService.REWARD_POOL
		if RandomService.randf_channel('chest_rolls') < REWARD_OVERRIDE_CHANCE:
			override_replacement_rolls = true
	else:
		print("Spawning progressive pool chest")
		item_pool = ItemService.PROGRESSIVE_POOL

func get_chest_tex() -> Texture2D:
	var texture : Texture2D
	if item_pool:
		if item_pool.resource_path in POOL_TEXTURES.keys():
			texture = POOL_TEXTURES[item_pool.resource_path]
	if not texture:
		texture = POOL_TEXTURES['default']
	return texture

func update_texture(tex : Texture2D) -> void:
	if not material_duped:
		dupe_material()
	var mat : StandardMaterial3D = chest.get_node('Chest').get_surface_override_material(0)
	mat.albedo_texture = tex

func dupe_material() -> void:
	var chest_mesh : MeshInstance3D = chest.get_node('Chest')
	var chest_lid : MeshInstance3D = chest.get_node('Lid')
	var mat : StandardMaterial3D = chest_mesh.mesh.surface_get_material(0).duplicate()
	chest_mesh.set_surface_override_material(0, mat)
	chest_lid.set_surface_override_material(0, mat)
	material_duped = true

func get_current_texture() -> Texture2D:
	return chest.get_node('Chest').get_surface_override_material(0).albedo_texture

func get_ray_gradient() -> Gradient:
	if ray_gradient:
		return ray_gradient
	if item_pool:
		if item_pool.resource_path in POOL_GRADIENTS:
			return load(POOL_GRADIENTS[item_pool.resource_path])
	return load(POOL_GRADIENTS['default'])

func set_ray_gradient(new_gradient : Gradient) -> void:
	if not ray_tex:
		ray_tex = GradientTexture2D.new()
		ray_tex.gradient = new_gradient
		ray_tex.fill_to = Vector2(0.0, 1.0)
	else:
		ray_tex.gradient = new_gradient
	light_ray.get_surface_override_material(0).set_shader_parameter('tex_frg_21', ray_tex)

func vanish() -> void:
	var dust_cloud = Globals.DUST_CLOUD.instantiate()
	get_tree().get_root().add_child(dust_cloud)
	dust_cloud.global_position = global_position
	queue_free()
