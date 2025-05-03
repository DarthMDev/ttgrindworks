extends Control


const TEX_LOCKED := preload('res://ui_assets/misc/lock.png')
const TEX_UNLOCKED := preload('res://ui_assets/misc/unlock.png')
const SAD_COLOR = Color("75a34b")
const LOW_LAFF_THRESHOLD := 0.2

## HP values
@export var max_laff := 15:
	set(x):
		max_laff = x
		update_hp()
@export var laff := 15:
	set(x):
		laff = x
		update_hp()
@export var extra_lives := 0:
	set(x):
		extra_lives = x
		update_extra_lives()

## Child references
@onready var meter := $Anchor/Meter
@onready var dead_face := $Anchor/Meter/Dead
@onready var healthy_face := $Anchor/Meter/Healthy
@onready var obscured_face := %ObscuredFaces
@onready var grin := $Anchor/Meter/Healthy/Grin
@onready var mouth := $Anchor/Meter/Healthy/Mouth
@onready var laff_eye := $Anchor/Meter/Healthy/Eyes/Health
@onready var max_eye := $Anchor/Meter/Healthy/Eyes/MaxHealth
@onready var animator := $AnimationPlayer

## Locals
var visible_teeth := 6
var hp_ref := 0
var low_laff_tween : Tween

## For Laff-Lock
var lock_enabled := false:
	set(x):
		lock_enabled = x
		%Lock.visible = x
var locked := false:
	set(x):
		locked = x
		if x:
			%Lock.set_texture(TEX_LOCKED)
		else:
			%Lock.set_texture(TEX_UNLOCKED)

@export var obscured := false:
	set(x):
		obscured = x
		await NodeGlobals.until_ready(self)
		update_hp()

func _ready() -> void:
	update_hp()

func update_hp():
	# Update eye text
	laff_eye.set_text(str(laff))
	max_eye.set_text(str(max_laff))
	
	if laff > hp_ref:
		animator.play('bounce')
	elif laff < hp_ref:
		animator.play('bounce_down')
	hp_ref = laff
	
	if float(laff) / float(max_laff) < LOW_LAFF_THRESHOLD:
		do_low_hp_tween()
	elif low_laff_tween and low_laff_tween.is_running():
		end_low_hp_tween()
	
	if obscured and laff > 0:
		healthy_face.hide()
		dead_face.hide()
		obscured_face.show()
		update_obscured_face()
		return
	else:
		healthy_face.show()
		obscured_face.hide()
	
	# Show grin/mouth
	if laff >= max_laff:
		if mouth.visible:
			grin.show()
			mouth.hide()
		return
	elif laff > 0:
		if dead_face.visible:
			dead_face.hide()
			healthy_face.show()
			meter.self_modulate = Util.get_player().toon.toon_dna.head_color
		if grin.visible:
			mouth.show()
			grin.hide()
	else:
		healthy_face.hide()
		meter.self_modulate = SAD_COLOR
		dead_face.show()
	
	# Calculate visible teeth
	var teeth_ratio := float(laff) / float(max_laff)
	var new_visible_teeth := 0
	while (1.0 / 6.0) * new_visible_teeth < teeth_ratio:
		new_visible_teeth += 1

	# Bounce if tooth amount changed
	if new_visible_teeth != visible_teeth:
		visible_teeth = new_visible_teeth

	# Make only the visible teeth visible
	for i in mouth.get_child_count():
		mouth.get_child(i).visible = i < visible_teeth

func update_obscured_face() -> void:
#	var perc : float = float(laff) / float(max_laff)
#	var hp_unit : float = 1.0 / obscured_face.get_child_count()
#	var face_index := ceili(perc / hp_unit) - 1
	var face_index := RandomService.randi_channel('true_random') % obscured_face.get_child_count()
	print('face index: %f' % face_index)
	for i in obscured_face.get_child_count():
		obscured_face.get_child(i).visible = i == face_index

func set_laff(hp: int):
	laff = hp
	DiscordManager.update_presence()


func set_max_laff(hp: int):
	max_laff = hp
	laff = laff
	DiscordManager.update_presence()

func update_extra_lives() -> void:
	%ReviveLabel.text = "x%s" % extra_lives
	%ReviveLabel.visible = extra_lives >= 1

## Sets the laff meter depending on Toon species
func set_meter(dna: ToonDNA) -> void:
	var species_name: String = ToonDNA.ToonSpecies.keys()[dna.species].to_lower()
	meter.texture = load(Globals.laff_meters[species_name])
	meter.self_modulate = dna.head_color
	if species_name == "monkey":
		meter.size.x = 106.0
	else:
		meter.size.x = 96.0

func do_low_hp_tween() -> void:
	if low_laff_tween and low_laff_tween.is_running():
		return
	low_laff_tween = create_tween().set_loops()
	low_laff_tween.tween_property(meter, 'modulate', Color.RED, 1.0)
	low_laff_tween.tween_property(meter, 'modulate', Color.WHITE, 1.0)

func end_low_hp_tween() -> void:
	if low_laff_tween and low_laff_tween.is_running():
		low_laff_tween.kill()
	meter.modulate = Color.WHITE

func hover() -> void:
	if Util.get_player() and Util.get_player().character:
		var player_char: PlayerCharacter = Util.get_player().character
		var char_name: String
		if player_char.random_character_stored_name:
			char_name = player_char.random_character_stored_name
		else:
			char_name = player_char.character_name
		var char_desc := player_char.character_summary
		var char_color := player_char.dna.head_color
		HoverManager.hover(char_desc, 18, 0.025, char_name, char_color.darkened(0.3))

func stop_hover() -> void:
	HoverManager.stop_hover()
