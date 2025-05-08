extends Resource
class_name PlayerCharacter

@export var character_name := 'Flippy'
@export_multiline var character_summary := ""
@export var dna: ToonDNA
@export var gag_loadout: GagLoadout
@export var starting_laff := 25
@export var starting_items: Array[Item]
@export var base_stats: BattleStats
## Displays the Toon at a different index than normal
@export var override_index := -1
@export var achievement_qualities: Dictionary[ProgressFile.GameAchievement, String] = {}


# sory
@export var random_character_stored_name := ""
@export var achievement_index : ProgressFile.GameAchievement = ProgressFile.GameAchievement.DEFEAT_COGS_1

func character_setup(player: Player):
	player.stats.max_hp = starting_laff
	player.stats.hp = starting_laff
	dna = dna.duplicate()
	
	for item: Item in starting_items:
		if not item.evergreen:
			ItemService.seen_item(item)
		if item.evergreen or item is ItemActive:
			item = item.duplicate()
		item.apply_item(player)

func get_unlocked() -> bool:
	# fipy always unlocked :)
	if character_name == "Flippy":
		return true
	
	## Set your character to this achievement index if you want them always unlocked
	if achievement_index == ProgressFile.GameAchievement.DEFEAT_COGS_1:
		return true
	
	return SaveFileService.progress_file.get_achievement_unlocked(achievement_index)

func get_true_summary() -> String:
	var desc := character_summary
	for entry in achievement_qualities.keys():
		if SaveFileService.is_achievement_unlocked(entry):
			desc += "\n- %s" % achievement_qualities[entry]
	return desc

## NEXT CHARACTER V1.1.2: CINDY SPRINKLES
## Can only access Throw
## Starts with Fedora
## Can't get more than 1 Turn
