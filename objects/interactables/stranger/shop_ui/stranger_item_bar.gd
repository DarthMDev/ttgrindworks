extends TextureRect

@onready var item_container: VBoxContainer = %ItemContainer
@onready var slider: VSlider = %ExternalSlider

const ITEM_ICON := preload("res://objects/interactables/stranger/shop_ui/stranger_item_icon.tscn")
var player: Player:
	get: return Util.get_player()

signal s_item_selected(item: Item)


func _ready() -> void:
	if not player: await Util.s_player_assigned
	ItemService.s_item_applied.connect(item_list_changed)
	populate_list()

func populate_list() -> void:
	for child in item_container.get_children():
		child.queue_free()
	
	for item in player.stats.items:
		if item.icon and not Item.ItemTag.STRANGER_NOTRADE in item.tags:
			add_item(item)
	if player.stats.current_active_item and not Item.ItemTag.STRANGER_NOTRADE in player.stats.current_active_item.tags:
		add_item(player.stats.current_active_item)

func add_item(item: Item) -> void:
	var new_icon: Control = ITEM_ICON.instantiate()
	new_icon.item = item
	item_container.add_child(new_icon)
	new_icon.s_icon_clicked.connect(item_selected.bind(new_icon))

func item_selected(icon: Control) -> void:
	icon.hide()
	s_item_selected.emit(icon.item)

func item_list_changed(_item) -> void:
	populate_list()

func item_deselected(item: Item) -> void:
	for child in item_container.get_children():
		if child.item == item and not child.visible:
			child.show()
