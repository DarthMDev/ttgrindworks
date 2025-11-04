extends Resource
class_name PlayerCharacter

enum Character {
	OTHER,
	FLIPPY,
	CLARA,
	WHEEZER,
	BESSIE,
	MOE,
	MYSTERY,
	PETE,
	OLDMAN,
}
@export var character_id := Character.OTHER

@export var character_name := 'Flippy'
@export_multiline var character_summary := ""
@export_multiline var character_blurb := ""
@export var dna: ToonDNA
@export var gag_loadout: GagLoadout
@export var starting_laff := 25
@export var starting_items: Array[Item]
@export var base_stats: BattleStats
@export var starting_gags: Dictionary[String, int] = {}
@export var additional_stats: Dictionary[String, Variant] = {}
## Displays the Toon at a different index than normal
@export var override_index := -1
@export var achievement_qualities: Dictionary[ProgressFile.GameAchievement, String] = {}
@export var achievement_items: Dictionary[ProgressFile.GameAchievement, Item] = {}
@export var item_discard_tags: Array[Item.ItemTag] = []

# sory
@export_storage var random_character_stored_name := ""
@export var achievement_index : ProgressFile.GameAchievement = ProgressFile.GameAchievement.DEFEAT_COGS_1

func character_setup(player: Player):
	player.stats.max_hp = starting_laff
	player.stats.hp = starting_laff
	for key in starting_gags.keys():
		player.stats.gags_unlocked[key] = starting_gags[key]
	for key in additional_stats.keys():
		player.stats.set(key, additional_stats[key])
	dna = dna.duplicate(true)
	
	for item: Item in get_starting_items():
		if not item.evergreen:
			ItemService.seen_item(item)
		if item.evergreen or item is ItemActive:
			item = item.duplicate(true)
		item.apply_item(player)
	

func get_unlocked() -> bool:
	# fipy always unlocked :)
	if character_id == Character.FLIPPY: return true
	
	return SaveFileService.progress_file.get_achievement_unlocked(achievement_index)

func get_true_summary() -> String:
	var desc := character_summary
	for entry in achievement_qualities.keys():
		if SaveFileService.is_achievement_unlocked(entry):
			desc += "\n%s" % achievement_qualities[entry]
	return desc

func get_starting_items() -> Array[Item]:
	var items: Array[Item] = []
	for item in starting_items:
		items.append(item)
	for key in achievement_items.keys():
		if SaveFileService.is_achievement_unlocked(key):
			items.append(achievement_items[key])
	return items
