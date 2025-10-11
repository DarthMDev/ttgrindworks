extends Label3D
class_name ExtraTurnItem

## Referencing the item directly would be a cyclical reference
const BASE_ITEM := 'res://objects/items/resources/passive/extra_turn.tres'

@onready var behind: Label3D = %Behind

func setup(item: Item) -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	# Ensure you can't go higher than the max turns
	if get_player_turns() > get_max_turns():
		item.reroll()

	fix_viewport(self)

func modify(ui: Label3D) -> void:
	fix_viewport(ui)

func fix_viewport(node: Label3D) -> void:
	# Hack fix because 4.3 Label3Ds don't work well in subviewports
	Util.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)
	if Util.get_viewport() != node.get_viewport():
		node.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)

func force_reset_text(node: Label3D) -> void:
	node.text = ''
	node.behind.text = ''
	node.text = '+1\nMove'
	node.behind.text = '+1\nMove'

func get_player_turns() -> int:
	if not Util.get_player():
		return -1
	var turns := Util.get_player().stats.turns
	turns += ItemService.get_items_in_play("Extra Move").size()
	return turns

func get_max_turns() -> int:
	if not Util.get_player():
		return Globals.MAX_TURNS
	return Util.get_player().stats.max_turns
