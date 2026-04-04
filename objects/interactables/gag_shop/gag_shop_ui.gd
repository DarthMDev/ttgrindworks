extends Control

var CHOICE_BUTTON: PackedScene:
	get:
		if not CHOICE_BUTTON: return GameLoader.load("res://objects/interactables/gag_shop/assets/alt_gag_choice.tscn")
		return CHOICE_BUTTON
var shop: GagShop
var alt_gags: Dictionary[ToonAttack, ToonAttack]:
	get: return shop.alt_gags
var selected_gag: ToonAttack

signal s_gag_purchased(old_gag: ToonAttack, new_gag: ToonAttack)
signal s_exit


func _init() -> void:
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'CHOICE_BUTTON' :"res://objects/interactables/gag_shop/assets/alt_gag_choice.tscn",
	})

func _ready() -> void:
	refresh()

func on_gag_button_pressed(gag: ToonAttack) -> void:
	select_gag(gag)

func select_gag(gag: ToonAttack) -> void:
	selected_gag = gag
	populate_choices()
	swap_pages()

func populate_choices() -> void:
	for child in %GagContainer.get_children():
		child.queue_free()
	
	var base_choice_button = CHOICE_BUTTON.instantiate()
	base_choice_button.gag = selected_gag
	%GagContainer.add_child(base_choice_button)
	base_choice_button.s_pressed.connect(swap_gag.bind(base_choice_button.gag))
	base_choice_button.button_text = "KEEP"
	
	var gags: Array[ToonAttack] = []
	for gag: ToonAttack in alt_gags.keys():
		if alt_gags[gag] == selected_gag:
			gags.append(gag)
	for gag in gags:
		var choice_button = CHOICE_BUTTON.instantiate()
		choice_button.gag = gag
		%GagContainer.add_child(choice_button)
		choice_button.s_pressed.connect(swap_gag.bind(choice_button.gag))

func swap_gag(gag: ToonAttack) -> void:
	s_gag_purchased.emit(selected_gag, gag)
	selected_gag = null
	swap_pages()
	refresh()

func swap_pages() -> void:
	%GagChoice.set_visible(not %GagChoice.visible)
	%AltChoices.set_visible(not %AltChoices.visible)

func exit_pressed() -> void:
	s_exit.emit()

func refresh() -> void:
	%GagPanel.refresh()
	var buttons: Dictionary = %GagPanel.get_buttons()
	for button: GagButton in buttons.keys():
		if buttons[button] in alt_gags.values(): button.enable()
		else: button.disable()
		if not button.pressed.is_connected(on_gag_button_pressed):
			button.pressed.connect(on_gag_button_pressed.bind(buttons[button]))
