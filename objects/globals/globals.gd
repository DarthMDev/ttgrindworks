extends Node

const VERSION_NUMBER := "v1.1.2a"

## Holds any value you may want accessible globally and quickly

func _init():
	set_meta(GameLoader.NO_LOADER_ASSURANCE, true)
	GameLoader.queue_into(GameLoader.Phase.GAME_START, self, {
		'GRUNT_COG_POOL': 'res://objects/cog/presets/pools/grunt_cogs.tres',
		'MOD_COG_POOL': 'res://objects/cog/presets/pools/mod_cogs.tres',
		'ALL_COGS_POOL': 'res://objects/cog/presets/pools/all_cogs.tres',
	})
	GameLoader.queue(GameLoader.Phase.AVATARS, [
		'res://objects/toon/bodies/fat_sml.tscn',
		'res://objects/toon/bodies/sml_med.tscn',
		'res://objects/toon/bodies/med_lrg.tscn',
		'res://objects/toon/bodies/fat_sml_skirt.tscn',
		'res://objects/toon/bodies/sml_med_skirt.tscn',
		'res://objects/toon/bodies/med_lrg_skirt.tscn',
		
		'res://objects/toon/head/dog_heads.tscn',
		'res://objects/toon/head/bear_heads.tscn',
		'res://objects/toon/head/cat_heads.tscn',
		'res://objects/toon/head/duck_heads.tscn',
		'res://objects/toon/head/horse_heads.tscn',
		'res://objects/toon/head/monkey_heads.tscn',
		'res://objects/toon/head/mouse_heads.tscn',
		'res://objects/toon/head/pig_heads.tscn',
		'res://objects/toon/head/rabbit_heads.tscn',

		'res://audio/sfx/toon/bear/speech_sounds.tres',
		'res://audio/sfx/toon/cat/speech_sounds.tres',
		'res://audio/sfx/toon/dog/speech_sounds.tres',
		'res://audio/sfx/toon/duck/speech_sounds.tres',
		'res://audio/sfx/toon/horse/speech_sounds.tres',
		'res://audio/sfx/toon/monkey/speech_sounds.tres',
		'res://audio/sfx/toon/mouse/speech_sounds.tres',
		'res://audio/sfx/toon/pig/speech_sounds.tres',
		'res://audio/sfx/toon/rabbit/speech_sounds.tres',
		
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-bear.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-cat.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-dog.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-duck.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-horse.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-monkey.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-mouse.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-pig.ogg',
		'res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-rabbit.ogg',
		
		'res://objects/cog/suita/suita.tscn',
		'res://objects/cog/suitb/suitb.tscn',
		'res://objects/cog/suitc/suitc.tscn',
		'res://objects/cog/suita/skelecog_a.tscn',
		'res://objects/cog/suitb/skelecog_b.tscn',
		'res://objects/cog/suitc/skelecog_c.tscn',
	])
	GameLoader.queue(GameLoader.Phase.AVATARS, TOON_UNLOCK_ORDER_PATHS)
	GameLoader.queue(GameLoader.Phase.AVATARS, ADDITIONAL_TOON_PATHS)
	GameLoader.queue_into(GameLoader.Phase.COG_BLDG_FLOOR, self, {
		'COG_BUILDING_SCENE': 'res://scenes/cog_building/cog_building_floor.tscn'
	})
	GameLoader.queue_into(GameLoader.Phase.FALLING_SEQ, self, {
		'FALLING_SCENE': 'res://scenes/falling_scene/falling_scene.tscn'
	})
	GameLoader.queue_into(GameLoader.Phase.GAMEPLAY, self, {
		'factory_floor_variant': 'res://scenes/game_floor/floor_variants/base_floors/the_factory.tres',
		'mint_floor_variant': 'res://scenes/game_floor/floor_variants/base_floors/mint.tres',
		'da_floor_variant': 'res://scenes/game_floor/floor_variants/base_floors/da_office.tres',
		'cgc_floor_variant': 'res://scenes/game_floor/floor_variants/base_floors/cog_golf_course.tres',
		
	})

func _ready() -> void:
	import_custom_cogs()
	Util.s_floor_started.connect(on_floor_start)
	print("Game Version: %s" % VERSION_NUMBER)
	
	# Emit one hour signal if best time is already lower than that
	var best_time := SaveFileService.progress_file.best_time
	if not is_equal_approx(best_time, 0.0):
		if best_time < 3600.0:
			s_one_hour_win.emit()

#region COGS:
# Bodies:
# type hinting CogDNA enum will cause a cyclic inheritance error
func fetch_suit(suit_type: int, skelecog: bool) -> PackedScene:
	match {'t': suit_type, 's': skelecog}:
		{'t': CogDNA.SuitType.SUIT_A, 's': false}:
			return GameLoader.load('res://objects/cog/suita/suita.tscn')
		{'t': CogDNA.SuitType.SUIT_B, 's': false}:
			return GameLoader.load('res://objects/cog/suitb/suitb.tscn')
		{'t': CogDNA.SuitType.SUIT_C, 's': false}:
			return GameLoader.load('res://objects/cog/suitc/suitc.tscn')
		{'t': CogDNA.SuitType.SUIT_A, 's': true}:
			return GameLoader.load('res://objects/cog/suita/skelecog_a.tscn')
		{'t': CogDNA.SuitType.SUIT_B, 's': true}:
			return GameLoader.load('res://objects/cog/suitb/skelecog_b.tscn')
		{'t': CogDNA.SuitType.SUIT_C, 's': true}:
			return GameLoader.load('res://objects/cog/suitc/skelecog_c.tscn')
	return null

## Player Characters
const TOON_UNLOCK_ORDER_PATHS := [
	'res://objects/player/characters/flippy.tres',
	'res://objects/player/characters/clerk_clara.tres',
	'res://objects/player/characters/julius_wheezer.tres',
	'res://objects/player/characters/barnacle_bessie.tres',
	'res://objects/player/characters/moe_zart.tres',
	'res://objects/player/characters/testchar.tres',
]
## Characters unlocked non-sequentially
var ADDITIONAL_TOON_PATHS := []

func fetch_toon_unlock_order() -> Array[PlayerCharacter]:
	var unlock_order: Array[PlayerCharacter]
	unlock_order.assign(TOON_UNLOCK_ORDER_PATHS.map(func(path): return GameLoader.load(path)))
	for path in ADDITIONAL_TOON_PATHS:
		var char : PlayerCharacter = GameLoader.load(path)
		if not char.override_index == -1: unlock_order.insert(char.override_index, char)
		else: unlock_order.append(char)
	return unlock_order

func get_unlocked_toons() -> Array[PlayerCharacter]:
	var unlocked_toons := fetch_toon_unlock_order()
	for character : PlayerCharacter in unlocked_toons.duplicate():
		if not character.get_unlocked():
			unlocked_toons.erase(character)
	return unlocked_toons

## Global Cog Pools
var GRUNT_COG_POOL: CogPool
var MOD_COG_POOL: CogPool

func add_standard_cog(cog_dna: CogDNA) -> void:
	GRUNT_COG_POOL.cogs.append(cog_dna)

func remove_standard_cog(cog_dna: CogDNA) -> void:
	GRUNT_COG_POOL.cogs.erase(cog_dna)

func add_proxy(cog_dna : CogDNA) -> void:
	MOD_COG_POOL.cogs.append(cog_dna)

func remove_proxy(cog_dna : CogDNA) -> void:
	MOD_COG_POOL.cogs.append(cog_dna)

## Custom Cogs
var ALL_COGS_POOL: CogPool
const COG_SAVE_PATH := "user://save/custom_cogs/"
const ACCEPTED_MODELS := ["glb", "gltf"]
const ACCEPTED_TEXTURES := ["png", "gltf"]
var loaded_custom_cogs : Dictionary[String, CogDNA] = {}
var custom_cog_head_directory := {}
var custom_cog_tex_directory := {}

func import_custom_cogs() -> void:
	if DirAccess.dir_exists_absolute(COG_SAVE_PATH):
		clean_old_custom_dna()
	clear_custom_cogs()
	if DirAccess.dir_exists_absolute(COG_SAVE_PATH):
		import_cog_heads()
		import_cog_head_textures()
		import_cog_dna()

## Converts existing custom cog dna files to json
func clean_old_custom_dna() -> void:
	for file_name in DirAccess.get_files_at(COG_SAVE_PATH):
		if file_name.get_extension() == "tres":
			var loaded_file = ResourceLoader.load(COG_SAVE_PATH + file_name)
			if loaded_file is CogDNA:
				save_cog_dna(loaded_file, cog_to_file_name(loaded_file.cog_name))
				DirAccess.remove_absolute(COG_SAVE_PATH + file_name)
				print("Converted %s dna to json format." % loaded_file.cog_name)

func save_cog_dna(dna : CogDNA, path : String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_line(dna.to_json())
	file.close()

func cog_to_file_name(cog_name : String) -> String:
	cog_name = (cog_name.replace(" ", "_")).to_lower()
	var file_name := cog_name
	return COG_SAVE_PATH + file_name + ".cog"

func import_cog_dna() -> void:
	for file_name in DirAccess.get_files_at(COG_SAVE_PATH):
		if not file_name.get_extension() == "cog":
			continue
		var loaded_file := FileAccess.open(COG_SAVE_PATH + file_name, FileAccess.READ)
		var json_string := ""
		while loaded_file.get_position() < loaded_file.get_length():
			json_string += loaded_file.get_line()
		var new_dna := CogDNA.from_json(json_string)
		loaded_custom_cogs[COG_SAVE_PATH + file_name] = new_dna
		if SaveFileService.settings_file.use_custom_cogs:
			if new_dna.is_mod_cog:
				add_proxy(new_dna)
			else:
				add_standard_cog(new_dna)

func clear_custom_cogs() -> void:
	clear_custom_dna(GRUNT_COG_POOL)
	clear_custom_dna(MOD_COG_POOL)
	custom_cog_head_directory.clear()
	custom_cog_tex_directory.clear()

func clear_custom_dna(pool : CogPool) -> void:
	for cog in pool.cogs.duplicate():
		if cog in loaded_custom_cogs.values():
			pool.cogs.erase(cog)

func import_cog_heads() -> void:
	for file in DirAccess.get_files_at(COG_SAVE_PATH):
		if file.get_extension() in ACCEPTED_MODELS:
			import_head(COG_SAVE_PATH + file)

func import_head(file_path : String) -> PackedScene:
	var node3d := Util.load_gltf_at_runtime(file_path)
	if node3d == null:
		print("Failed to load Cog head at runtime")
	else:
		print("Successfully loaded Cog head at path %s" % file_path)
		var packed_head := pack_head(node3d)
		packed_head.set_path(file_path)
		custom_cog_head_directory[file_path] = packed_head
		return packed_head
	return null

func pack_head(head : Node3D) -> PackedScene:
	var packed_head := PackedScene.new()
	if packed_head.pack(head) == OK:
		return packed_head
	return null

func import_cog_head_textures() -> void:
	for file in DirAccess.get_files_at(COG_SAVE_PATH):
		if file.get_extension() in ACCEPTED_TEXTURES:
			custom_cog_tex_directory[COG_SAVE_PATH + file] = ImageTexture.create_from_image(Image.load_from_file(COG_SAVE_PATH + file))

#endregion

## Gag Colors
func get_gag_color(gag : ToonAttack) -> Color:
	if gag is GagSquirt: return Color('f733b8')
	elif gag is GagTrap: return Color('fcfd55')
	elif gag is GagLure: return Color('489f3f')
	elif gag is GagSound: return Color('4f63d5')
	elif gag is GagThrow: return Color('ed8a42')
	elif gag is GagDrop: return Color('35f4ff')
	return Color.WHITE

## DNA:
var dna_colors := {
	white =  Color.WHITE,
	peach = Color('#F7B0B2'),
	bright_red = Color('#EE4347'),
	red = Color('#DC676A'),
	maroon = Color('#B53B6F'),
	sienna = Color('#917229'),
	brown = Color('#A35A44'),
	tan = Color('#FEB182'),
	coral = Color('#D47F4C'),
	orange = Color('#FD7A2B'),
	yellow = Color('#FEE551'),
	cream = Color('#FEF498'),
	citrine = Color('#DAEE7D'),
	lime = Color('#8CD252'),
	sea_green = Color('#3EBD83'),
	green = Color('#4DF766'),
	light_blue = Color('#6EE7D5'),
	aqua = Color('#58D1F3'),
	blue = Color('#318FC5'),
	periwinkle = Color('#8E96DF'),
	royal_blue = Color('#4954B9'),
	slate_blue = Color('#7561D2'),
	purple = Color('#8B48BF'),
	lavender = Color('#B978DB'),
	pink = Color('#E59DE7'),
	plum = Color('#B2B2CC'),
	black = Color('#4C4C59')
}
var random_dna_color : Color:
	get:
		return dna_colors[dna_colors.keys()[RandomService.randi_channel('true_random') % dna_colors.keys().size()]]

## Toon Bodies
# type hinting ToonDNA enum will cause a cyclic inheritance error
func fetch_toon_body(body_type: int, skirt: bool) -> PackedScene:
	match {'b': body_type, 's': skirt}:
		{'b': ToonDNA.BodyType.SMALL, 's': false}:
			return GameLoader.load('res://objects/toon/bodies/fat_sml.tscn')
		{'b': ToonDNA.BodyType.MEDIUM, 's': false}:
			return GameLoader.load('res://objects/toon/bodies/sml_med.tscn')
		{'b': ToonDNA.BodyType.LARGE, 's': false}:
			return GameLoader.load('res://objects/toon/bodies/med_lrg.tscn')
		{'b': ToonDNA.BodyType.SMALL, 's': true}:
			return GameLoader.load('res://objects/toon/bodies/fat_sml_skirt.tscn')
		{'b': ToonDNA.BodyType.MEDIUM, 's': true}:
			return GameLoader.load('res://objects/toon/bodies/sml_med_skirt.tscn')
		{'b': ToonDNA.BodyType.LARGE, 's': true}:
			return GameLoader.load('res://objects/toon/bodies/med_lrg_skirt.tscn')
	return null

# type hinting ToonDNA enum will cause a cyclic inheritance error
func fetch_toon_head(species: int) -> PackedScene:
	match species:
		ToonDNA.ToonSpecies.BEAR:
			return GameLoader.load('res://objects/toon/head/bear_heads.tscn')
		ToonDNA.ToonSpecies.CAT:
			return GameLoader.load('res://objects/toon/head/cat_heads.tscn')
		ToonDNA.ToonSpecies.DOG:
			return GameLoader.load('res://objects/toon/head/dog_heads.tscn')
		ToonDNA.ToonSpecies.DUCK:
			return GameLoader.load('res://objects/toon/head/duck_heads.tscn')
		ToonDNA.ToonSpecies.HORSE:
			return GameLoader.load('res://objects/toon/head/horse_heads.tscn')
		ToonDNA.ToonSpecies.MONKEY:
			return GameLoader.load('res://objects/toon/head/monkey_heads.tscn')
		ToonDNA.ToonSpecies.MOUSE:
			return GameLoader.load('res://objects/toon/head/mouse_heads.tscn')
		ToonDNA.ToonSpecies.PIG:
			return GameLoader.load('res://objects/toon/head/pig_heads.tscn')
		ToonDNA.ToonSpecies.RABBIT:
			return GameLoader.load('res://objects/toon/head/rabbit_heads.tscn')
	return null

#region SPECIES SFX
enum ToonDial {
	YELP,
	HOWL,
	SPEAK_LONG,
	SPEAK_MED,
	SPEAK_SHORT,
	QUESTION,
	FALLING
}

func get_species_sfx(speech_type : ToonDial, dna : ToonDNA) -> AudioStream:
	if not dna:
		return null

	if speech_type == ToonDial.FALLING:
		match dna.species:
			ToonDNA.ToonSpecies.BEAR:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-bear.ogg')
			ToonDNA.ToonSpecies.CAT:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-cat.ogg')
			ToonDNA.ToonSpecies.DOG:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-dog.ogg')
			ToonDNA.ToonSpecies.DUCK:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-duck.ogg')
			ToonDNA.ToonSpecies.HORSE:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-horse.ogg')
			ToonDNA.ToonSpecies.MONKEY:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-monkey.ogg')
			ToonDNA.ToonSpecies.MOUSE:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-mouse.ogg')
			ToonDNA.ToonSpecies.PIG:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-pig.ogg')
			ToonDNA.ToonSpecies.RABBIT:
				return GameLoader.load('res://audio/sfx/sequences/elevator_trick/elevator_trick_fall-rabbit.ogg')

	var speech_sounds: ToonSpeechSounds
	match dna.species:
		ToonDNA.ToonSpecies.BEAR:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/bear/speech_sounds.tres')
		ToonDNA.ToonSpecies.CAT:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/cat/speech_sounds.tres')
		ToonDNA.ToonSpecies.DOG:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/dog/speech_sounds.tres')
		ToonDNA.ToonSpecies.DUCK:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/duck/speech_sounds.tres')
		ToonDNA.ToonSpecies.HORSE:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/horse/speech_sounds.tres')
		ToonDNA.ToonSpecies.MONKEY:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/monkey/speech_sounds.tres')
		ToonDNA.ToonSpecies.MOUSE:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/mouse/speech_sounds.tres')
		ToonDNA.ToonSpecies.PIG:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/pig/speech_sounds.tres')
		ToonDNA.ToonSpecies.RABBIT:
			speech_sounds = GameLoader.load('res://audio/sfx/toon/rabbit/speech_sounds.tres')
	if not speech_sounds:
		return null
			
	match speech_type:
		ToonDial.YELP:
			return speech_sounds.exclaim
		ToonDial.HOWL:
			return speech_sounds.howl
		ToonDial.SPEAK_LONG:
			return speech_sounds.long
		ToonDial.SPEAK_MED:
			return speech_sounds.med
		ToonDial.SPEAK_SHORT:
			return speech_sounds.short
		ToonDial.QUESTION:
			return speech_sounds.question
		_:
			return null
#endregion

## Laff Meters
var laff_meters := {
	bear ="res://ui_assets/player_ui/laff_meter/bear.png",
	cat ="res://ui_assets/player_ui/laff_meter/cat.png",
	dog ="res://ui_assets/player_ui/laff_meter/dog.png",
	duck ="res://ui_assets/player_ui/laff_meter/duck.png",
	horse ="res://ui_assets/player_ui/laff_meter/horse.png",
	monkey ="res://ui_assets/player_ui/laff_meter/monkey.png",
	mouse ="res://ui_assets/player_ui/laff_meter/mouse.png",
	pig ="res://ui_assets/player_ui/laff_meter/pig.png",
	rabbit ="res://ui_assets/player_ui/laff_meter/rabbit.png"
}

## Toon Clothing
var random_shirt : ToonShirt:
	get:
		var files := DirAccess.get_files_at('res://objects/toon/clothing/shirts')
		return Util.universal_load('res://objects/toon/clothing/shirts/'+files[RandomService.randi_channel('true_random')%files.size()])
var random_shorts : ToonBottoms:
	get:
		var files := DirAccess.get_files_at('res://objects/toon/clothing/shorts')
		return Util.universal_load('res://objects/toon/clothing/shorts/'+files[RandomService.randi_channel('true_random')%files.size()])
var random_skirt : ToonBottoms:
	get:
		var files := DirAccess.get_files_at('res://objects/toon/clothing/skirts')
		return Util.universal_load('res://objects/toon/clothing/skirts/'+files[RandomService.randi_channel('true_random')%files.size()])

## For toon names
const TOON_NAME_FILE := 'res://objects/toon/toon_names.txt'
var names_title : Array[String] = []
var names_first : Array[String] = []
var names_last_prefix : Array[String] = []
var names_last_suffix : Array[String] = []

func get_random_toon_name() -> String:
	if names_title.is_empty():
		parse_names()
	
	var random_name := ""
	var need_last_name := true
	
	# 50% chance of including a title name
	if RandomService.randi_channel('true_random') % 2 == 0:
		random_name += names_title[RandomService.randi_channel('true_random') % names_title.size()] + " "
	# 75% chance of having a first name
	if RandomService.randi_channel('true_random') % 4 == 0:
		need_last_name = false
		random_name += names_first[RandomService.randi_channel('true_random') % names_first.size()] + " "
	# 50% chance of last name, or give one if no first name
	if need_last_name or RandomService.randi_channel('true_random') % 2 == 0:
		random_name += names_last_prefix[RandomService.randi_channel('true_random') % names_last_prefix.size()]
		random_name += names_last_suffix[RandomService.randi_channel('true_random') % names_last_suffix.size()]
	
	return random_name

func parse_names() -> void:
	if not FileAccess.file_exists(TOON_NAME_FILE):
		print('no file exists at: ' + TOON_NAME_FILE)
	var name_file := FileAccess.open(TOON_NAME_FILE,FileAccess.READ)
	var names := name_file.get_as_text().split("\n")
	for name_line in names:
		var parsed_line : PackedStringArray = name_line.split("*")
		if parsed_line.size() < 3:
			continue
		var category := int(parsed_line[1])
		# Add name to proper category
		if category < 3:
			names_title.append(parsed_line[2])
		elif category < 6:
			names_first.append(parsed_line[2])
		elif category == 7:
			names_last_prefix.append(parsed_line[2])
		elif category == 8:
			names_last_suffix.append(parsed_line[2])

## Battle Globals
const SUIT_LURE_DISTANCE = 1.5
const SQUIRT_COLOR := Color('abb6ff')
const ACCURACY_GUARANTEE_HIT := 999
const ACCURACY_GUARANTEE_MISS := -999
var PROXY_CHANCE_MAXIMUM := 0.5

## Misc:
const SENSITIVITY = .005 # Mouse Sensitivity
const PLAYER_COLLISION_LAYER := 2
const HAZARD_COLLISION_LAYER := 3
var MAX_TURNS := 3
var MAX_POINT_REGEN := 2
var factory_floor_variant: FloorVariant
var mint_floor_variant: FloorVariant
var da_floor_variant: FloorVariant
var cgc_floor_variant: FloorVariant
var reward_chest_chance := 0.4
var floor_difficulty_increase := 1.0 / 3.0
var FLOOR_VARIANTS: Array[FloorVariant]:
	get:
		return [
			factory_floor_variant,
			mint_floor_variant,
			da_floor_variant,
			cgc_floor_variant,
		]

## Common Scenes
var DUST_CLOUD: PackedScene:
	get:
		return GameLoader.load('res://objects/props/etc/dust_cloud/dust_cloud.tscn')
var EXPLOSION: PackedScene:
	get:
		return GameLoader.load('res://models/cogs/misc/explosion/cog_explosion.tscn')
var TREASURE_CHEST: PackedScene:
	get:
		return GameLoader.load("res://objects/interactables/treasure_chest/treasure_chest.tscn")
var COG_BUILDING_SCENE: PackedScene
var FALLING_SCENE: PackedScene

## Lawbot Puzzles
var lawbot_puzzles := {
	avoid_skulls = PuzzleAvoidSkulls.new(),
	matching = PuzzleMatching.new(),
	skull_finder = PuzzleSkullFinder.new(),
	drag_three = PuzzleDragThree.new(),
	run = PuzzleRun.new(),
}
var random_puzzle: LawbotPuzzleGrid:
	get:
		return lawbot_puzzles[lawbot_puzzles.keys()[RandomService.randi_channel('puzzles')%lawbot_puzzles.keys().size()]].duplicate()

## Achievement Signals
signal s_character_unlocked(character: PlayerCharacter)
signal s_clown_boss_defeated
signal s_slendercog_boss_defeated
signal s_doodle_obtained
signal s_secret_floor
signal s_cog_volcano
signal s_one_hour_win
signal s_hundred_jellybeans
signal s_achievement_unlocked

func on_floor_start(game_floor: GameFloor) -> void:
	var floor_name := game_floor.floor_variant.floor_name.to_lower()
	if floor_name.contains('haunted') or floor_name.contains('faulty'):
		s_secret_floor.emit()

const MaxToonupConsumables := 3


#region Global Signals
signal s_game_paused(pause_menu)
signal s_title_screen_entered(title_screen)
signal s_game_started
signal s_chest_spawned(chest: TreasureChest)
signal s_entered_barrel_room
signal s_entered_penthouse
signal s_settings_opened
signal s_mystery_win
signal s_radio_spawned(radio: Node3D)
signal s_slendercog_boss_initialized(directory: Node3D)
#endregion
