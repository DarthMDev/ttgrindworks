extends Control
class_name ChatterboxMenu

var choice_amount := 3
@export var item_pool : ItemPool

@onready var items : Array[Item] = []

@export var offline := false

@onready var panels : Array[ChatterboxChoice] = [
	$ChatterboxChoices/ChatterboxChoice1,
	$ChatterboxChoices/ChatterboxChoice2,
	$ChatterboxChoices/ChatterboxChoice3
]

@onready var timer: GameTimer = $BattleTimer
var voting_time := 20

var twitch_voters : Dictionary[String, int] = {}

var total_votes := 0
var votes : Array[int] = [0, 0, 0]

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed('pause'):
	#	resume()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	$AnimationPlayer.play("chatterbox_on")
	
	timer.start(voting_time)
	timer.s_timeout.connect(collect)
	
	var i = 0
	for panel in panels:
		items.insert(i, ItemService.get_random_item(item_pool, false))
		panel.item_rect.texture = items[i].icon
		panel.bubble.set_text(Util.get_item_description(items[i]))
		panel.node_viewer.set_item(items[i])
		i += 1
	update_vote_labels()
	if !Util.twitch_active and !offline:
		collect()
	else:
		set_up_commands()

var commands : Array[TwitchCommand] = []

func set_up_commands() -> void:
	for i in range(choice_amount):
		var new_cmd = TwitchCommand.new()
		add_child(new_cmd)
		commands.insert(i, new_cmd)
		commands[i].command_received.connect(set_vote.bind(i))
		commands[i].command = str(i + 1)

func set_vote(from_username: String, info: TwitchCommandInfo, args: PackedStringArray, voted: int) -> void:
	if from_username not in twitch_voters.keys():
		twitch_voters.set(from_username, -1)
	if twitch_voters[from_username] == voted:
		print("Chatterbox: " + from_username + " attempted to vote " + str(voted + 1) + " again")
		return
	else:
		if twitch_voters[from_username] != -1:
			votes[twitch_voters[from_username]] -= 1
		twitch_voters[from_username] = voted
	print("Chatterbox: Setting vote for " + from_username + " to " + str(voted + 1))
	AudioManager.play_sound(load("res://audio/sfx/ui/sfx_pop.ogg"))
	votes[voted] += 1
	update_vote_labels()

func update_vote_labels() -> void:
	var i := 0
	for panel in panels:
		panel.extra_vote_label.text = "!" + str(i + 1)
		panel.vote_label.text = "!" + str(i + 1) + ": " + items[i].item_name + "\nVotes: " + str(votes[i])
		i += 1

func choose_item() -> Item:
	var i := 0
	var candidate: Array[int] = [0,0]
	for tally in votes:
		if tally > candidate[1]:
			candidate[0] = i
			candidate[1] = tally
		i += 1
	return items[candidate[0]]
	
func collect() -> void:
	var item = choose_item()
	
	# Check if the item is evergreen
	if not item.evergreen and not item is ItemActive:
		ItemService.seen_item(item)
	elif item is ItemActive:
		if not item.evergreen:
			ItemService.seen_item(item)
		item = item.duplicate()
	else:
		item = item.duplicate()
	# Mark the item as in play
	ItemService.item_created(item)
	
	item.apply_item(Util.get_player())
	# Show UI
	var ui = load('res://objects/items/ui/item_get_ui/item_get_ui.tscn').instantiate()
	ui.item = item
	get_tree().get_root().add_child(ui)
	
	# Play the item collection sound
	item.play_collection_sound()
	resume()

func resume() -> void:
	get_tree().paused = false
	queue_free()
