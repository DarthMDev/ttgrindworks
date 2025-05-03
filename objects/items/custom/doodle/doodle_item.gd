extends Node3D

const NAME_FILE := "res://objects/doodle/doodle_names.txt"
const FAKE_EVERGREEN_ENABLED := true
const ITEM_PATH := 'res://objects/items/resources/passive/doodle.tres'

## Doodle obj
@onready var doodle : RoamingDoodle = $RoamingDoodle

var possible_descriptions : Array[String] = [
	"Your new best friend!"
]

func _ready():
	doodle.state = doodle.DoodleState.STOPPED

func setup(item : Item):
	var name_file := FileAccess.open(NAME_FILE,FileAccess.READ)
	var names := name_file.get_as_text().split("\n")
	names.remove_at(names.size() - 1)
	var name_line := names[RandomService.randi_channel('true_random') % names.size()]
	var new_name := name_line.split("*")[2]
	item.item_name = new_name
	item.item_description = possible_descriptions[RandomService.randi_channel('true_random')%possible_descriptions.size()]
	
	## Double check that there is definitely no other doodles available
	#for resource in ItemService.items_in_play:
		#if resource.item_description in possible_descriptions:
			#if not resource == item:
				#item.reroll()
	
	# Item is evergreen so that it can have arbitrary data.
	# This script will still put the item into seen
	#if FAKE_EVERGREEN_ENABLED:
		#ItemService.seen_item(load(ITEM_PATH))

func modify(model : Node3D):
	model.get_child(0).state = doodle.DoodleState.STOPPED
	model.get_child(0).doodle.dna = doodle.doodle.dna
	model.get_child(0).doodle.apply_dna()

func custom_collect():
	Util.get_player().partners.append(doodle)
	SceneLoader.add_persistent_node(doodle)
	doodle.rotation = Vector3(0,0,0)
	doodle.state = RoamingDoodle.DoodleState.NAVIGATE
	doodle.following_player = true
	Globals.s_doodle_obtained.emit()
