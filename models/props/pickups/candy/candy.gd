@tool
extends Node3D

var item: Item

func setup(resource: Item):
	item = resource
	if 'damage' in item.stats_add:
		candy_type = CandyType.SUPER_DAMAGE if 'super' in item.arbitrary_data else CandyType.DAMAGE
	elif 'defense' in item.stats_add:
		candy_type = CandyType.SUPER_DEFENSE if 'super' in item.arbitrary_data else CandyType.DEFENSE
	elif 'evasiveness' in item.stats_add:
		candy_type = CandyType.SUPER_EVASIVENESS if 'super' in item.arbitrary_data else CandyType.EVASIVENESS
	elif 'luck' in item.stats_add:
		candy_type = CandyType.SUPER_LUCK if 'super' in item.arbitrary_data else CandyType.LUCK
	elif 'speed' in item.stats_add:
		candy_type = CandyType.SPEED
	elif 'active_charge' in item.stats_add:
		candy_type = CandyType.BATTERY
		if not is_battery_valid():
			item.reroll()

func modify(ui: Node3D) -> void:
	ui.candy_type = candy_type
	ui.particles.emitting = false
	ui.particles.hide()

#region Visuals

enum CandyType {
	DAMAGE, DEFENSE, EVASIVENESS, LUCK, SPEED,
	SUPER_DAMAGE, SUPER_DEFENSE, SUPER_EVASIVENESS, SUPER_LUCK,
	BATTERY
}

const SuperTypes = [
	CandyType.SUPER_DAMAGE, CandyType.SUPER_DEFENSE, CandyType.SUPER_EVASIVENESS,
	CandyType.SUPER_LUCK,
]

const CandyColors: Dictionary = {
	CandyType.DAMAGE: Color(1, 0.477, 0.203),
	CandyType.SUPER_DAMAGE: Color(0.849, 0.235, 0.299),
	CandyType.DEFENSE: Color(0.305, 0.368, 0.914),
	CandyType.SUPER_DEFENSE: Color(0.524, 0.298, 0.824),
	CandyType.EVASIVENESS: Color(0.956, 0.44, 0.867),
	CandyType.SUPER_EVASIVENESS: Color(0.343, 0.78, 0.649),
	CandyType.LUCK: Color(0, 0.798, 0.384),
	CandyType.SUPER_LUCK: Color(0, 0.748, 0.85),
	CandyType.SPEED: Color(1, 0.304, 0.313),
	CandyType.BATTERY: Color(0.212, 0.212, 0.252),
}

const ParticleColors: Dictionary = {
	CandyType.SUPER_DAMAGE: Color("fff599"),
	CandyType.SUPER_DEFENSE: Color("b3faff"),
	CandyType.SUPER_EVASIVENESS: Color("b3faff"),
	CandyType.SUPER_LUCK: Color("ff988c"),
}

const CandyMaterials: Dictionary = {
	CandyType.DAMAGE: preload("res://models/props/pickups/candy/candy_overlay_arrows.tres"),
	CandyType.DEFENSE: preload("res://models/props/pickups/candy/candy_overlay_bubbles.tres"),
	CandyType.EVASIVENESS: preload("res://models/props/pickups/candy/candy_overlay_target.tres"),
	CandyType.LUCK: preload("res://models/props/pickups/candy/candy_overlay_stars.tres"),
	CandyType.SPEED: preload("res://models/props/pickups/candy/candy_overlay_stripes.tres"),
	CandyType.SUPER_DAMAGE: preload("res://models/props/pickups/candy/candy_overlay_arrows.tres"),
	CandyType.SUPER_DEFENSE: preload("res://models/props/pickups/candy/candy_overlay_bubbles.tres"),
	CandyType.SUPER_EVASIVENESS: preload("res://models/props/pickups/candy/candy_overlay_target.tres"),
	CandyType.SUPER_LUCK: preload("res://models/props/pickups/candy/candy_overlay_stars.tres"),
	CandyType.BATTERY: preload("res://models/props/pickups/candy/candy_overlay_lightning.tres")
}

@export var candy_type := CandyType.DAMAGE:
	set(x):
		candy_type = x
		await NodeGlobals.until_ready(self)
		_update_candy_visual()

@onready var candy: MeshInstance3D = $Cube_001
@onready var particles: GPUParticles3D = %Particles

func _ready() -> void:
	_update_candy_visual()

func _update_candy_visual() -> void:
	candy.get_surface_override_material(0).albedo_color = CandyColors[candy_type]
	candy.get_surface_override_material(0).next_pass = CandyMaterials[candy_type]
	if candy_type in SuperTypes:
		particles.process_material.color = ParticleColors[candy_type]
		particles.emitting = true
		particles.show()
	else:
		particles.emitting = false
		particles.hide()

#endregion

#region Misc. Logic

## Check for battery validity
## Battery is valid if a player has an uncharged active item
func is_battery_valid() -> bool:
	var player := Util.get_player()
	if not is_instance_valid(player):
		return true
	
	var active_item := player.stats.current_active_item
	if not active_item or active_item.charge_count == active_item.current_charge:
		return false
	
	return true


#endregion
