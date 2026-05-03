@icon("res://addons/toonlike_tools/icons/diamond_red.png")
extends FiniteStateMachine3D

var next_character: PlayerCharacter

@onready var selected_toon: Toon = %Toon
@onready var teleport_hole: Node3D = %TeleportHole
@export var character_clipboard: Control

class FallAnim:
	static var anims: Array[FallAnim]
	static var anim_weights: PackedFloat32Array
	var anim_name: String
	var seek: float
	var weight: float
	
	func _init(_anim_name, _seek, _weight):
		self.anim_name = _anim_name
		self.seek = max(_seek, 0.0)
		anims.append(self)
		anim_weights.append(_weight)
		
	func apply_to_toon(toon: Toon):
		toon.set_animation(anim_name)
		toon.anim_seek(seek)
		
	static func random() -> FallAnim:
		return anims[RNG.channel(RNG.ChannelTrueRandom).rand_weighted(anim_weights)]

func start(character: PlayerCharacter):
	next_character = character
	selected_toon.construct_toon(character.dna)
	selected_toon.show()
	request(&'TeleportIn')

func teleport_out_and_finish():
	while current_state_name != &'Idle':
		await state_changed
	await selected_toon.teleport_out()
	selected_toon.hide()
	request(&'')

func finish():
	while current_state_name != &'Idle':
		await state_changed
	request(&'')

func character_selected(character: PlayerCharacter):
	# This can only happen with Mystery Toon
	if next_character.character_id == character.character_id:
		if current_state_name == &'Idle':
			poof_refresh()
			return
	
	next_character = character
	if current_state_name == &'Idle':
		request(&'Melt')

func _fall_or_land(character: PlayerCharacter):
	var state_name: StringName
	if character != next_character:
		state_name = &'FallThrough'
	else:
		state_name = &'Land'
	states[state_name].character = character
	request(state_name)

func _fall_or_idle(character: PlayerCharacter):
	var state_name: StringName
	if character != next_character:
		state_name = &'Melt'
	else:
		state_name = &'Idle'
	request(state_name)

func _ready() -> void:
	teleport_hole.get_node('AnimationPlayer').play('shrink')

func poof_refresh() -> void:
	var dust_cloud: Node3D = Globals.DUST_CLOUD.instantiate()
	selected_toon.add_child(dust_cloud)
	dust_cloud.position += Vector3(0.0, 1.0, 0.4)
	dust_cloud.scale *= 1.5
	selected_toon.construct_toon(character_clipboard.character.dna)
	selected_toon.set_animation('neutral')
