extends Label3D

var BOOST_RANGE := Vector2i(2, 6)
const BASE_RESOURCE := "res://objects/items/resources/passive/laff_boost.tres"

@onready var behind: Label3D = %Behind

var item: Item


func setup(resource: Item):
	item = resource
	if resource.stats_add['max_hp'] == 0:
		if Util.floor_number > 5:
			BOOST_RANGE = Vector2i(3, 6)
		var boost := RandomService.randi_range_channel('laff_boosts', BOOST_RANGE.x, BOOST_RANGE.y)
		resource.stats_add['max_hp'] = boost
		resource.stats_add['hp'] = boost

	var label_text := "+" + str(resource.stats_add['max_hp'])
	set_text(label_text)
	behind.set_text(label_text)

	fix_viewport(self)

func fix_viewport(node: Label3D) -> void:
	# Hack fix because 4.3 Label3Ds don't work well in subviewports
	Util.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)
	if Util.get_viewport() != node.get_viewport():
		node.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)

func force_reset_text(node: Label3D) -> void:
	node.text = ''
	node.behind.text = ''
	node.text = "+" + str(item.stats_add['max_hp'])
	node.behind.text = "+" + str(item.stats_add['max_hp'])

func modify(ui: Label3D) -> void:
	var label_text := "+" + str(item.stats_add['max_hp'])
	ui.set_text(label_text)
	ui.behind.set_text(label_text)
	fix_viewport(ui)
