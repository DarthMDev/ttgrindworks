extends CanvasLayer

@onready var star_container := $UI/QualityDisplay/StarContainer

@export_category('Star Icons')
@export var star_filled: Texture2D
@export var star_unfilled: Texture2D

# Locals
var item_name: String:
	set(x):
		$UI/NameLabel.set_text(x)
	get:
		return $UI/NameLabel.text
var description: String:
	set(x):
		$UI/Description.set_text(x)
	get:
		return $UI/Description.text

var item: WorldItem
var reacting := false
var reactions_enabled: bool:
	get:
		return SaveFileService.settings_file.item_reactions

func _ready():
	$UI.hide()

func set_item(new_item: WorldItem) -> void:
	
	# Hide old description
	if is_instance_valid(item):
		item.description_bubble.force_hide = true
	
	# Ensure item is valid
	item = new_item
	var res : Item
	if is_instance_valid(item):
		res = item.item
	
	if not item:
		reacting = false
		Util.get_player().toon.set_emotion(Toon.Emotion.NEUTRAL)
		return
	
	if Util.get_player().see_descriptions:
		item.description_bubble.force_hide = false
	
	if reactions_enabled:
		reacting = true
		do_reaction(int(res.qualitoon))
	else:
		if reacting:
			Util.get_player().toon.set_emotion(Toon.Emotion.NEUTRAL)
			reacting = false

func set_stars(stars: int):
	for i in star_container.get_child_count():
		if i < stars:
			star_container.get_child(i).texture = star_filled
		else:
			star_container.get_child(i).texture = star_unfilled

func _process(_delta):
	var closest_dist := -1.0
	var closest_item : WorldItem
	for itm in ItemService.items_in_proximity:
		if not is_instance_valid(itm):
			ItemService.item_left_proximity(itm)
			continue
		var dist = abs(itm.global_position.distance_to(Util.get_player().global_position))
		if dist < closest_dist or closest_dist < 0.0:
			closest_item = itm
			closest_dist  = dist
	
	if not closest_item == item or (not item and reacting):
		set_item(closest_item)

func do_reaction(qualitoon: int):
	match qualitoon:
		0:
			Util.get_player().toon.set_emotion(Toon.Emotion.SAD)
		_:
			Util.get_player().toon.set_emotion((qualitoon + 1) as Toon.Emotion)
