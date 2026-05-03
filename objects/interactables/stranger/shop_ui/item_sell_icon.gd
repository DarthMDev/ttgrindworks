extends TextureRect


@onready var cancel_button: GeneralButton = %CancelButton

var item: Item

signal s_item_canceled(item: Item)


func set_item(new_item: Item) -> void:
	item = new_item
	var star_total := 0
	if item:
		%Icon.set_texture(item.icon)
		%Icon.material = item.icon_material
		star_total = item.qualitoon as int + 1
		cancel_button.show()
		%ValueContainer.show()
	else:
		%Icon.set_texture(null)
		cancel_button.hide()
		%ValueContainer.hide()
	
	%PriceLabel.set_text("x%d" % star_total)

func cancel_pressed() -> void:
	var canceled_item: Item = item
	set_item(null)
	s_item_canceled.emit(canceled_item)
