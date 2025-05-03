extends Label3D
class_name PointBoostItem

const BASE_ITEM := 'res://objects/items/resources/passive/point_boost.tres'

const OUTLINE_COLORS := {
	"Trap": Color("3a3a01"),
	"Lure": Color("173a13"),
	"Sound": Color("0f1542"),
	"Throw": Color("541e00"),
	"Squirt": Color("6a024c"),
	"Drop": Color("004347")
}

@onready var behind: Label3D = %Behind

var resource: Item
var tween: Tween:
	set(x):
		if tween and tween.is_valid():
			tween.kill()
		tween = x

func setup(new_resource: Item) -> void:
	
	resource = new_resource
	resource.item_name = "Gag Point Boost"

	fix_viewport(self)
	start_tween()

func start_tween() -> void:
	var seqs: Array = []
	for track_name: String in OUTLINE_COLORS.keys():
		if not Util.get_player().stats.character.gag_loadout.has_track_of_name(track_name):
			continue
		seqs.append(Parallel.new([
			LerpProperty.new(self, ^"modulate", 1.0, Util.get_player().stats.character.gag_loadout.get_track_of_name(track_name).track_color),
			LerpProperty.new(behind, ^"modulate", 1.0, Util.get_player().stats.character.gag_loadout.get_track_of_name(track_name).track_color),
			LerpProperty.new(self, ^"outline_modulate", 1.0, OUTLINE_COLORS[track_name]),
			LerpProperty.new(behind, ^"outline_modulate", 1.0, OUTLINE_COLORS[track_name]),
		]))
	tween = Sequence.new(seqs).as_tween(self).set_loops()

func fix_viewport(node: Label3D) -> void:
	# Hack fix because 4.3 Label3Ds don't work well in subviewports
	Util.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)
	if Util.get_viewport() != node.get_viewport():
		node.get_viewport().size_changed.connect(force_reset_text.bind(node), CONNECT_REFERENCE_COUNTED)

func force_reset_text(node: Label3D) -> void:
	node.text = ''
	node.behind.text = ''
	node.text = "+1"
	node.behind.text = "+1"

func collect() -> void:
	# Boost all tracks by 1
	for track in Util.get_player().stats.gag_balance.keys():
		Util.get_player().stats.gag_regeneration[track] += 1

func modify(ui: Label3D) -> void:
	ui.modulate = modulate
	ui.outline_modulate = outline_modulate
	ui.behind.modulate = modulate
	ui.behind.outline_modulate = outline_modulate
	fix_viewport(ui)
	ui.start_tween()
