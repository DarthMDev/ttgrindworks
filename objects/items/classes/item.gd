extends Resource
class_name Item

enum QualitoonRating {
	Q1,
	Q2,
	Q3,
	Q4,
	Q5,
}

enum Rarity {
	NIL,
	Q1,
	Q2,
	Q3,
	Q4,
	Q5,
	Q6,
	Q7
}

const RarityToRolls: Dictionary[Rarity, int] = {
	Rarity.Q1: 0,
	Rarity.Q2: 1,
	Rarity.Q3: 2,
	Rarity.Q4: 3,
	Rarity.Q5: 4,
	Rarity.Q6: 5,
	Rarity.Q7: 6,
}

const QualityToRarity: Dictionary[QualitoonRating, Rarity] = {
	QualitoonRating.Q1: Rarity.Q1,
	QualitoonRating.Q2: Rarity.Q2,
	QualitoonRating.Q3: Rarity.Q3,
	QualitoonRating.Q4: Rarity.Q4,
	QualitoonRating.Q5: Rarity.Q5,
}

enum ItemTag {
	GAG_POINT_RELATED,
}

@export_flags(
	"GAG_POINT_RELATED:1",
) var item_tags

## The in-game displayed qualitoon of an item
@export var qualitoon: QualitoonRating
## Item rarity value. Q0 = Super duper common. Q7 = Super duper rare. Nil uses qualitoon as rarity.
@export var rarity: Rarity = Rarity.NIL
## Evergreen items can appear multiple times per-run.
@export var evergreen := false
## Realtime items exist and run processes in the game world.
## They have to be marked to properly spawn in the game world when a save is loaded.
@export var realtime := false

enum ItemSlot {
	PASSIVE,
	HAT,
	GLASSES,
	BACKPACK,
}
@export var slot := ItemSlot.PASSIVE
@export var world_scale := 1.0
@export var world_y_offset := 0.0
@export var want_ui_spin := true
@export var ui_cam_offset := 0.0

@export var item_name: String
@export_multiline var item_description: String
@export_multiline var big_description: String
@export var model: PackedScene

## Plays a sound on world item pickup
@export var pickup_sfx: AudioStream

# Stat effects
@export var stats_add: Dictionary
@export var stats_multiply: Dictionary

## Key should be the string name of a value
## Entry should be the value to set the variable to
@export var player_values: Dictionary

## Arbitrary data holds any values you may want access to later
@export var arbitrary_data: Dictionary

## Optional Script to run with the player
@export var item_script: Script

## Whether the object should be saved to the run file
@export var remember_item := true

## The icon to display the item on the UI
@export var icon: Texture2D

## What to display as the shop title for boost items
## This is only really used for the doodle item
@export var shop_category_title := "Boost Item"

## What to display as the shop title COLOR
@export var shop_category_color := Color("3294ea")
@export var force_show_shop_category := false
## Overrides shop price. No override if set to 0.
@export var custom_shop_price: int = 0

## Should only be needed on initial setup
var guarantee_collection := false
## Disallows reroll signal to be emitted
var rerollable := true

var is_acessory: bool:
	get: return slot in [ItemSlot.HAT, ItemSlot.GLASSES, ItemSlot.BACKPACK]

## Reroll request
signal s_reroll

func reroll() -> void:
	if rerollable:
		print(item_name + ": Reroll signal sent")
		s_reroll.emit()
	else:
		print(item_name + ": Attempted to reroll, but was unable to")

## Applies item stats and script.
func apply_item(player: Player, _apply_visuals := true, object : Node3D = null) -> void:
	apply_item_script(player, object)
	apply_item_stats(player)
	run_item_config(player)

func apply_item_stats(player : Player) -> void:
	var stats := player.stats
	
	for stat in stats_add:
		if stat == 'active_charge':
			stats.charge_active_item(stats_add[stat])
			continue
		if str(stat) in stats:
			if stat == 'money':
				print("Calling special money func")
				stats.add_money(stats_add[stat])
			elif stat == 'max_hp' or stat == 'hp':
				stats[stat] += stats_add[stat] + player.stats.laff_boost_boost
			else:
				stats[stat] += stats_add[stat]
	
	for stat in stats_multiply:
		if str(stat) in stats:
			stats[stat] *= stats_multiply[stat]
		elif stat.begins_with("gag_boost:"):
			var track: String = stat.get_slice(":",1)
			if track in stats.gag_effectiveness:
				stats.gag_effectiveness[track] *= stats_multiply[stat]
	
	for value in player_values:
		player.set(value, player_values[value])

func apply_item_script(player : Player, object : Node3D = null) -> void:
	if item_script:
		var item_node := ItemScript.add_item_script(player,item_script)
		if item_node is ItemScript:
			if not is_instance_valid(Util.get_player()):
				await Util.s_player_assigned
			item_node.on_collect(self,object)

func run_item_config(player : Player) -> void:
	# Check the model for custom item setups
	if model:
		rerollable = false
		var mod: Node3D = model.instantiate()
		Util.add_child(mod)
		if mod.has_method('setup'):
			mod.setup(self)
		if mod.has_method('collect'):
			mod.collect()
		mod.queue_free()
	
	if remember_item and not self is ItemActive:
		player.stats.items.append(self)
		print('added %s to item list' % item_name)
		ItemService.s_item_applied.emit(self)

const SFX_FALLBACK := 'res://audio/sfx/misc/MG_pairing_all_matched.ogg'
func play_collection_sound() -> void:
	if pickup_sfx:
		AudioManager.play_sound(pickup_sfx)
	else:
		AudioManager.play_sound(load(SFX_FALLBACK))

func get_shop_price() -> int:
	var base_price: float
	if custom_shop_price != 0:
		base_price = custom_shop_price
	else:
		base_price = 2.0 + float(qualitoon as int + 1) * 7.0
	return roundi(base_price)

func remove_item(player : Player) -> void:
	# If these stats are in stats_add/mult
	# They will not be undone
	var excluded_stats : Array[String] =[
		"active_charge",
		"money",
	]
	var stats := player.stats
	
	# Undo stat boosts
	for stat in stats_add:
		if not stat in excluded_stats and stat in stats:
			stats[stat] -= stats_add[stat]
	for stat in stats_multiply:
		if not stat in excluded_stats and stat in stats:
			stats[stat] *= 1.0 / stats_multiply[stat]
	
	# Undo player values
	for value in player_values:
		if player_values[value] is bool:
			player.set(value, not player_values[value])
		else:
			printerr("Data type of %s is not set up to be un-applied in item class!" % value)
	
	# Remove item node
	for node in player.item_node.get_children():
		if node is ItemScript and node.get_script() == item_script:
			node.on_item_removed()
			node.queue_free()
			break
	
	# Remove self from player's item list
	stats.items.erase(self)
	
	print("Successfully removed item: %s." % item_name)

func get_true_rarity() -> Rarity:
	if rarity == Rarity.NIL:
		return qualitoon as Rarity
	else:
		return rarity

static func get_item_flag_value(item : Item, flag : ItemTag) -> bool:
	return item.item_tags & flag
