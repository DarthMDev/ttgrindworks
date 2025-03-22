extends Resource
class_name SaveFile

@export var player_stats: PlayerStats
@export var current_seed: int
@export var seed_channels := {}
@export var floor_number := -1
@export var seen_items: Array[Item] = []
@export var items_in_play: Array[Item] = []
@export var player_dna: ToonDNA
@export var game_time := 0.0
@export var floor_choice : FloorVariant = null

func save_to(file_name: String):
	ResourceSaver.save(self, SaveFileService.SAVE_FILE_PATH + file_name)

func get_run_info():
	if Util.get_player() and is_instance_valid(Util.get_player()):
		player_stats = Util.get_player().stats
	current_seed = RandomService.base_seed
	seed_channels = RandomService.channels.duplicate()
	floor_number = Util.floor_number
	seen_items = ItemService.seen_items
	items_in_play = ItemService.items_in_play
	player_dna = Util.get_player().toon.toon_dna
	game_time = Util.get_player().game_timer.time
