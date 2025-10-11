extends VSlider

@export var external_scroll_container: ScrollContainer

func _ready() -> void:
	if external_scroll_container:
		process_priority = 1
		value_changed.connect(
			func (_value):
				external_scroll_container.get_v_scroll_bar().value = value
		)
	else:
		set_process(false)

func _process(_delta: float) -> void:
	var ext_vscroll := external_scroll_container.get_v_scroll_bar()
	min_value = ext_vscroll.min_value
	max_value =  ext_vscroll.max_value - ext_vscroll.page
	#page = ext_vscroll.page
	var new_val := ext_vscroll.value
	if not is_equal_approx(value, new_val):
		value = new_val
