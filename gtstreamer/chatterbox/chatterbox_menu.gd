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

var votes : Array[int] = [0, 0, 0]

var sweetener_range := 7
var final_sweeteners : Dictionary[String, int] = {}

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
	var first_picks = []

	for panel in panels:
		items.insert(i, ItemService.get_random_item(item_pool, false))
		panel.item_rect.texture = items[i].icon
		panel.bubble.set_text(Util.get_item_description(items[i]))
		panel.node_viewer.set_item(items[i])
		var first_swt: String = RandomService.array_pick_random("chatterbox", 
			Util.stat_strings.filter(func(x): return x not in first_picks)
		)
		var second_swt: String = RandomService.array_pick_random("chatterbox", 
			Util.stat_strings.filter(func(x): return x != first_swt)
		)
		panel.sweeteners = [
			[first_swt, RandomService.randi_range_channel("chatterbox", 2, sweetener_range)],
			[second_swt, -RandomService.randi_range_channel("chatterbox", 2, sweetener_range)],
		]
		first_picks.append(first_swt)
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

func set_vote(username: String, info: TwitchCommandInfo, args: PackedStringArray, vote: int) -> void:
	if username not in twitch_voters.keys():
		twitch_voters.set(username, -1)
	if username in twitch_voters:
		print("Chatterbox: " + username + " attempted to vote " + str(vote + 1) + " again")
		return
	else:
		if username in twitch_voters:
			votes[twitch_voters[username]] -= 1
		twitch_voters[username] = vote
	print("Chatterbox: Setting vote for " + username + " to " + str(vote + 1))
	AudioManager.play_sound(load("res://audio/sfx/ui/sfx_pop.ogg"))
	votes[vote] += 1
	update_vote_labels()

func update_vote_labels() -> void:
	var i := 0
	for panel in panels:
		panel.extra_vote_label.text = "!" + str(i + 1)
		panel.vote_label.text = "\nVotes: " + str(votes[i])
		i += 1
	
func collect() -> void:
	var highest_idx: int = -1
	var highest_vote: int = -1

	# Pick the item
	for i in range(votes.size()):
		if votes[i] > highest_vote:
			highest_idx = i
			highest_vote = votes[i]
		elif votes[i] == highest_vote:
			highest_idx = RandomService.array_pick_random("vote_tie", [i, highest_idx])

	# Feed the sweets
	for sweetener in panels[highest_idx].sweeteners:
		Util.get_player().stats[sweetener[0]] += float(sweetener[1]) * 0.01

	var item = items[highest_idx]
	
	# Check if the item is evergreen
	if not item.evergreen:
		ItemService.seen_item(item)
	if not item is ItemActive:
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
