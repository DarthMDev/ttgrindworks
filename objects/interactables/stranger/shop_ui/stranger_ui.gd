extends Control

var player: Player:
	get: return Util.get_player()

## Emits the item that was received only
signal s_item_traded
signal s_exit
signal s_shift_left
signal s_shift_right

func _ready() -> void:
	item_display_setup()
	set_confirm_enabled(false)

func set_page_visible(index: int) -> void:
	for i in %Pages.get_child_count():
		%Pages.get_child(i).set_visible(i == index)

func close_window() -> void:
	cancel_trade()
	s_exit.emit()
	set_page_visible(0)

#region CATALOG UI
var current_item: Item
var free_items: Array[Item] = []

func item_focused(item: Item, free := false) -> void:
	current_item = item
	%DescPanel.hide()
	%TradeButton.text = "Trade"
	if item:
		show_item_details(item)
		if free:
			%PriceLabel.set_text("x0")
			%TradeButton.text = "Swap"
			if not item in free_items:
				free_items.append(item)
	else:
		catalog_null_out()

func show_item_details(item: Item) -> void:
	%ItemLabel.set_text(item.item_name)
	%PriceLabel.set_text("x%d" % (item.get_true_rarity() as int + 1))
	%DescLabel.set_text(item.item_description)
	%TradeButton.set_disabled(false)
	%TradeButton.material.set_shader_parameter(&"alpha", 1.0)
	if not (item is ItemAccessory or item is ItemActive or item is ItemShoe or item.force_show_shop_category):
		return
	%DescPanel.show()
	for i in %RatingContainer.get_child_count():
		if i <= item.qualitoon as int:
			%RatingContainer.get_child(i).set_texture(star_tex)
		else:
			%RatingContainer.get_child(i).set_texture(star_tex_unfilled)
	%DescTitle.set_text(item.shop_category_title)
	%DescTitle.label_settings.font_color = item.shop_category_color

func catalog_null_out() -> void:
	%DescPanel.hide()
	%ItemLabel.set_text("SOLD OUT!")
	%PriceLabel.set_text("x0")
	%DescLabel.set_text("")
	%TradeButton.disabled = true
	%TradeButton.material.set_shader_parameter(&"alpha", 0.5)

func on_trade_pressed() -> void:
	if current_item in free_items:
		confirm_trade()
	else:
		set_trade_item(current_item)
		set_page_visible(1)

func left_pressed() -> void:
	s_shift_left.emit()

func right_pressed() -> void:
	s_shift_right.emit()

#endregion

#region TRADE UI
const COLOR_UNDER := Color.YELLOW
const COLOR_OVER := Color.RED
const COLOR_CORRECT := Color.GREEN

@onready var item_bar: TextureRect = %StrangerItemBar

var trade_item: Item
var star_tex: Texture2D:
	get: return GameLoader.load("res://ui_assets/misc/quality_star.png")
var star_tex_unfilled: Texture2D:
	get: return GameLoader.load("res://ui_assets/misc/quality_star_unfilled.png")
var price := 8
var selected_items: Array[Item] = []

func refresh_total() -> void:
	var total_stars := 0
	for item_icon: Control in %ItemContainer.get_children():
		if item_icon.item:
			total_stars += item_icon.item.qualitoon as int + 1
	
	for i in %StarContainer.get_child_count():
		var star_icon: TextureRect = %StarContainer.get_child(i)
		if i >= price:
			star_icon.hide()
			continue
		star_icon.show()
		if i < total_stars:
			star_icon.set_texture(star_tex)
		else:
			star_icon.set_texture(star_tex_unfilled)
	%StarCountLabel.set_text("Stars: %d/%d" % [total_stars, price])
	
	# Exact change only, please!
	if total_stars < price:
		%StarCountLabel.label_settings.font_color = COLOR_UNDER
	else:
		%StarCountLabel.label_settings.font_color = COLOR_CORRECT
	set_confirm_enabled(%StarCountLabel.label_settings.font_color == COLOR_CORRECT)


func on_item_trade_primed(item: Item) -> void:
	select_item(item)

func select_item(item: Item) -> void:
	if selected_items.size() >= 3:
		deselect_item(item)
		return
	selected_items.append(item)
	refresh_selected_items()
	refresh_total()

func deselect_item(item: Item) -> void:
	selected_items.erase(item)
	refresh_selected_items()
	refresh_total()
	item_bar.item_deselected(item)

func refresh_selected_items() -> void:
	for i in %ItemContainer.get_child_count():
		var item: Item = null
		if selected_items.size() - 1 >= i:
			item = selected_items[i]
		%ItemContainer.get_child(i).set_item(item)

func item_display_setup() -> void:
	pass

func set_confirm_enabled(enable: bool) -> void:
	%ConfirmButton.disabled = not enable
	if enable: %ConfirmButton.modulate.a = 1.0
	else: %ConfirmButton.modulate.a = 0.5

func set_trade_item(item: Item) -> void:
	trade_item = item
	%ItemNameLabel.set_text(item.item_name)
	price = item.get_true_rarity() as int + 1
	refresh_total()

func cancel_trade() -> void:
	for item in selected_items.duplicate(true):
		deselect_item(item)
	trade_item = null
	price = 0
	set_page_visible(0)

func confirm_trade() -> void:
	for item in selected_items:
		item.remove_item(player)
	item_bar.populate_list()
	catalog_null_out()
	cancel_trade()
	s_item_traded.emit()

#endregion

func _process(_delta) -> void:
	if not visible: return
	if Input.is_action_just_pressed('pause'):
		close_window()
	if not %Pages.get_child(0).visible:
		return
	if Input.is_action_just_pressed("move_left"):
		left_pressed()
	elif Input.is_action_just_pressed("move_right"):
		right_pressed()
