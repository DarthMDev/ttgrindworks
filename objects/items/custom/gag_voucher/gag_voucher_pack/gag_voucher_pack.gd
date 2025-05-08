extends Node3D

var item: Item
var gag_track: String

func setup(new_item: Item) -> void:
	item = new_item
	get_node('GagVoucher').setup(item)
	gag_track = get_node('GagVoucher').gag_track
	item.item_description = "3 %s vouchers!" % gag_track
	item.big_description = item.item_description

func collect() -> void:
	Util.get_player().stats.gag_vouchers[gag_track] += 3

func modify(ui_asset: Node3D) -> void:
	get_node('GagVoucher').modify(ui_asset.get_node('GagVoucher'))
