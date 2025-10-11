@tool
extends Control

const PULLOUT_X := -10.0
const FULLOUT_X := -20.0

var sfx_hover: AudioStream:
	get: return GameLoader.load("res://audio/sfx/ui/GUI_rollover.ogg")
var sfx_click: AudioStream:
	get: return GameLoader.load("res://audio/sfx/ui/Click.ogg")

@export var h_offset: float = 0.0:
	set(x):
		h_offset = x
		if not is_node_ready():
			await ready
		$Tab.position.x = h_offset + h_offset_offset
@export var rainbow_effect := false:
	set(x):
		rainbow_effect = x
		match x:
			true: start_rainbow()
			_: stop_rainbow()

@onready var tab: TextureRect = %Tab
@onready var char_label: Label = %CharLabel

var character: PlayerCharacter
var selected := false:
	set(x):
		selected = x
		if x: push_tab(FULLOUT_X)
		else: push_tab()
var hovered := false
var push_tween: Tween
## The variable below is for animating that is all dw about it
var h_offset_offset: float = 0.0:
	set(x):
		h_offset_offset = x
		$Tab.position.x = h_offset + x
var rainbow_tween: Tween

signal s_clicked(char: PlayerCharacter)


func set_character(new_character: PlayerCharacter) -> void:
	character = new_character
	char_label.set_text(character.character_name)
	tab.self_modulate = character.dna.head_color
	if new_character.character_name == 'Mystery Toon':
		rainbow_effect = true

func mouse_entered() -> void:
	hovered = true
	if not selected:
		push_tab(PULLOUT_X, 0.05)
		AudioManager.play_sound(sfx_hover)

func mouse_exited() -> void:
	hovered = false
	if not selected:
		push_tab()

func push_tab(xpos := 0.0, time := 0.2) -> void:
	if push_tween and push_tween.is_running():
		push_tween.kill()
	
	push_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	push_tween.tween_property(self, 'h_offset_offset', xpos, time)
	push_tween.finished.connect(push_tween.kill)

func gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked()

func clicked() -> void:
	s_clicked.emit(character)
	AudioManager.play_sound(sfx_click)

func start_rainbow() -> void:
	stop_rainbow()
	var tween_time := 2.0
	var new_color: Color = tab.self_modulate
	while new_color.is_equal_approx(tab.self_modulate):
		new_color = Globals.random_dna_color
	rainbow_tween = create_tween()
	rainbow_tween.tween_property(tab, 'self_modulate', new_color, tween_time)
	rainbow_tween.finished.connect(start_rainbow)

func stop_rainbow() -> void:
	if rainbow_tween and rainbow_tween.is_running():
		rainbow_tween.kill()
