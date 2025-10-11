extends Node
class_name CogversationPlayer

var cogs := {}
@export var starter_cogversations: Array[Cogversation]
var current_cogversation: Cogversation
var restart_timer: Timer


func _ready() -> void:
	restart_timer = Timer.new()
	restart_timer.one_shot = true
	add_child(restart_timer)

func start_cogversation(talking_cogs: Array[Cog]):
	# Fill the cog dict with the new cogs
	for cog in talking_cogs:
		cogs[cog] = Cogversation.new()
	
	start_new_cogversation()

## Plays the cogversation message, and awaits a moment before replying
func queue_cogversation(cogversation: Cogversation, cog: Cog):
	if cogversation.reply_to_index != -1:
		cog = current_cogversation.to_array()[cogversation.reply_to_index].speaker
	cogs[cog] = cogversation
	cogversation.speaker = cog
	await cog.speak(cogversation.message)
	if cogversation.follow_up:
		queue_cogversation(cogversation.follow_up, get_random_cog([cog]))
	else:
		start_new_cogversation()

## Queues a random starter cogversation
func start_new_cogversation() -> void:
	restart_timer.wait_time = randf() * 20.0
	restart_timer.start()
	await restart_timer.timeout
	current_cogversation = starter_cogversations.pick_random().duplicate(true)
	queue_cogversation(current_cogversation, get_random_cog())

## Returns a random Cog excluding any specified 
func get_random_cog(exclude: Array[Cog] = []) -> Cog:
	var valid_cogs: Array[Cog] = []
	for cog in cogs.keys():
		if not exclude.has(cog):
			valid_cogs.append(cog)

	if not valid_cogs.is_empty():
		return valid_cogs.pick_random()
	else:
		return cogs.keys().pick_random()
