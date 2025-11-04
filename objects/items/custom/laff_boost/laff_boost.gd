extends Label3D


const BASE_RESOURCE := "res://objects/items/resources/passive/laff_boost.tres"
const BOOST_RANGES: Dictionary[String, Vector2i]= {
	"default": Vector2i(2, 6),
	"res://objects/items/pools/battle_clears.tres": Vector2i(1, 3),
	"res://objects/items/pools/progressives.tres": Vector2i(3, 5),
	"res://objects/items/pools/rewards.tres": Vector2i(4, 7),
}
const COST_PER_POINT := 4

@onready var behind: Label3D = %Behind

var item: Item


func setup(resource: Item):
	item = resource
	if resource.stats_add['max_hp'] == 0:
		var boost := RNG.channel(RNG.ChannelLaffBoosts).randi_range(get_boost_range().x, get_boost_range().y)
		resource.stats_add['max_hp'] = boost
		resource.stats_add['hp'] = boost
		resource.custom_shop_price = COST_PER_POINT * boost

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

func get_boost_range() -> Vector2i:
	var world_item: WorldItem = NodeGlobals.get_ancestor_of_type(self, WorldItem)
	if not world_item:
		return BOOST_RANGES['default']
	if world_item.pool.resource_path in BOOST_RANGES.keys():
		return BOOST_RANGES[world_item.pool.resource_path]
	return BOOST_RANGES['default']
