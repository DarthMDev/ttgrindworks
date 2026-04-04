extends Control

const MAX_CHAR_TABS := 8
const TAB_SIZE_Y := 49.0

var CHAR_TAB: PackedScene:
	get: return GameLoader.load("res://scenes/title_screen/character_select/character_tab.tscn")


@onready var char_tabs: VBoxContainer = %CharTabs
@onready var laff_meter: Control = %LaffMeter
@onready var name_label: Label = %ToonName
@onready var summary_label: RichTextLabel = %ToonSummary
@onready var ability_label: RichTextLabel = %ToonDetails
@onready var stat_container: HBoxContainer = %StatContainer
@onready var gag_container: GridContainer = %GagContainer
@onready var item_container: GridContainer = %ItemContainer
@onready var enter_button: TextureRect = %EnterTexture

var char_pos := 0
var character: PlayerCharacter
var current_tab: Control
var is_mystery_toon := false
var enter_button_tilt := -15.0
var enter_button_shrink := 0.85
var custom_seed: String:
	get:
		return %SeedEdit.text.to_lower()
var re := RegEx.new()

signal s_character_selected(character: PlayerCharacter)
signal s_play_pressed


func _ready() -> void:
	# Await a half-second in case a character is unlocked when the title screen is entered
	await Task.delay(0.5)
	
	character = GameLoader.load("res://objects/player/characters/flippy.tres")
	re.compile(r"[^a-z0-9]+")
	update_display()
	populate_tabs()
	
	if char_tabs.get_child_count() > MAX_CHAR_TABS:
		%CharButtonUp.show()
		%CharButtonDown.show()

func update_display() -> void:
	clear_display()

	name_label.set_text(character.character_name)
	name_label.label_settings.font_size = 28
	while name_label.label_settings.font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.label_settings.font_size).x > 320.0:
		name_label.label_settings.font_size -= 1

	summary_label.set_text(character.character_blurb)
	laff_meter.set_meter(character.dna)
	if not is_mystery_toon:
		laff_meter.max_eye.set_text(str(character.starting_laff))
		laff_meter.laff_eye.set_text(str(character.starting_laff))
	else:
		laff_meter.laff_eye.set_text("?")
		laff_meter.max_eye.set_text("?")
		add_questionmarks()

	ability_label.set_text("[ul]" + character.get_true_summary())

	for child in stat_container.get_children():
		var stat_name := child.name.to_lower()
		var stat_value: float
		if stat_name in character.base_stats:
			stat_value = character.base_stats.get(stat_name)
		elif stat_name in character.additional_stats.keys():
			stat_value = character.additional_stats[stat_name]
		if stat_value and not is_mystery_toon:
			child.get_node('StatLabel').set_text(Util.float_to_perc(stat_value))
		else:
			child.get_node('StatLabel').set_text("???")

	for track: Track in character.gag_loadout.loadout:
		if character.starting_gags.keys().has(track.track_name):
			if character.starting_gags[track.track_name] == 0: continue
			var new_icon := create_icon(track.gags[character.starting_gags[track.track_name] - 1].icon)
			new_icon.mouse_entered.connect(HoverManager.hover.bind(track.gags[character.starting_gags[track.track_name] - 1].action_name))
			new_icon.mouse_exited.connect(HoverManager.stop_hover)
			gag_container.add_child(new_icon)

	for item in character.get_starting_items():
		if item.icon:
			var new_icon := create_icon(item.icon)
			new_icon.mouse_entered.connect(Util.do_item_hover.bind(item))
			new_icon.mouse_exited.connect(HoverManager.stop_hover)
			item_container.add_child(new_icon)

func add_questionmarks() -> void:
	var qmark: Texture2D = load("res://ui_assets/pick_a_toon/questionmark.png")
	
	var newmark := create_icon(qmark)
	newmark.mouse_entered.connect(HoverManager.hover.bind("Random Offensive Track"))
	newmark.mouse_exited.connect(HoverManager.stop_hover)
	newmark.self_modulate = Color(1.0, 0.312, 0.248, 1.0)
	gag_container.add_child(newmark)
	
	newmark = create_icon(qmark)
	newmark.mouse_entered.connect(HoverManager.hover.bind("Random Support Track"))
	newmark.mouse_exited.connect(HoverManager.stop_hover)
	newmark.self_modulate = Color(0.0, 0.649, 0.826, 1.0)
	gag_container.add_child(newmark)
	
	newmark = create_icon(qmark)
	newmark.mouse_entered.connect(HoverManager.hover.bind("Random Accessory"))
	newmark.mouse_exited.connect(HoverManager.stop_hover)
	newmark.self_modulate = Color(0.848, 0.803, 0.41, 1.0)
	item_container.add_child(newmark)
	
	newmark = create_icon(qmark)
	newmark.mouse_entered.connect(HoverManager.hover.bind("Random Pocket Prank"))
	newmark.mouse_exited.connect(HoverManager.stop_hover)
	newmark.self_modulate = Color(0.305, 0.951, 0.488, 1.0)
	item_container.add_child(newmark)

func create_icon(icon: Texture2D) -> TextureRect:
	var new_icon := TextureRect.new()
	new_icon.custom_minimum_size = Vector2(24.0, 24.0)
	new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	new_icon.set_texture(icon)
	return new_icon

func clear_display() -> void:
	for child in gag_container.get_children():
		child.queue_free()
	for child in item_container.get_children():
		child.queue_free()

func populate_tabs() -> void:
	for toon in Globals.get_unlocked_toons():
		var char_tab: Control = CHAR_TAB.instantiate()
		char_tabs.add_child(char_tab)
		char_tab.set_character(toon)
		char_tab.s_clicked.connect(on_tab_clicked.bind(char_tab))
		char_tab.selected = toon == character
		Task.delay(0.1).connect(func(): if is_instance_valid(self): char_tab.h_offset = -char_tab.char_label.size.x / 2.5)
		if Globals.get_unlocked_toons().find(toon) == 0:
			char_tab.selected = true
			current_tab = char_tab

func on_tab_clicked(new_character: PlayerCharacter, tab: Control) -> void:
	if tab == current_tab and not new_character.character_id == PlayerCharacter.Character.MYSTERY:
		return
	
	character = new_character
	if character.character_name == "Mystery Toon":
		character = randomize_mystery_toon(character)
		is_mystery_toon = true
	else:
		is_mystery_toon = false
	update_display()
	if current_tab:
		current_tab.selected = false
	tab.selected = true
	current_tab = tab
	s_character_selected.emit(character)

func randomize_mystery_toon(res: PlayerCharacter) -> PlayerCharacter:
	RNG.generate_seed()
	res = res.duplicate(true)
	res.character_name = Globals.get_random_toon_name()
	res.dna.randomize_dna()
	return res

func play_pressed() -> void:
	s_play_pressed.emit()

func char_list_up() -> void:
	char_tabs.position.y += TAB_SIZE_Y
	char_pos -= 1
	%CharButtonUp.set_disabled(char_pos == 0)
	%CharButtonDown.set_disabled(char_pos == char_tabs.get_child_count() - MAX_CHAR_TABS)

func char_list_down() -> void:
	char_tabs.position.y -= TAB_SIZE_Y
	char_pos += 1
	%CharButtonUp.set_disabled(char_pos == 0)
	%CharButtonDown.set_disabled(char_pos == char_tabs.get_child_count() - MAX_CHAR_TABS)

func hover_text(text: String) -> void:
	HoverManager.hover(text)

func stop_hover() -> void:
	HoverManager.stop_hover()

func enter_hovered() -> void:
	enter_button.rotation_degrees = enter_button_tilt

func enter_unhovered() -> void:
	enter_button.rotation_degrees = 0.0

func enter_down() -> void:
	enter_button.self_modulate = Color.BLACK
	enter_button.scale = Vector2.ONE * enter_button_shrink

func enter_up() -> void:
	enter_button.self_modulate = Color.WHITE
	enter_button.scale = Vector2.ONE

func  _input(event):
	if event is InputEventMouseButton and event.pressed:
		if not Rect2(%SeedEdit.global_position, %SeedEdit.size).has_point(event.global_position):
			%SeedEdit.release_focus()

func seed_entered(new_seed: String) -> void:
	if new_seed == "":
		return

	var _caret_column = %SeedEdit.caret_column
	var _adjusted := new_seed.to_lower()
	_adjusted = re.sub(_adjusted, "", true)
	%SeedEdit.set_text(_adjusted)
	var length_diff: int = new_seed.length() - _adjusted.length()
	%SeedEdit.caret_column = _caret_column - length_diff
