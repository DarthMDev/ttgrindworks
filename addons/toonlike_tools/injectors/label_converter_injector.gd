@tool
extends EditorContextMenuPlugin

func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() != 1:
		return

	var node: Node = EditorInterface.get_edited_scene_root().get_node(paths[0])
	if is_instance_of(node, Label):
		add_context_menu_item(
			"Create equivalent RichTextLabel",
			_to_rich,
			EditorInterface.get_base_control().get_theme_icon(&"RichTextLabel", &"EditorIcons")
		)
	elif is_instance_of(node, RichTextLabel):
		add_context_menu_item(
			"Create equivalent Label",
			_to_regular,
			EditorInterface.get_base_control().get_theme_icon(&"Label", &"EditorIcons")
		)

func _to_rich(arr: Array) -> void:
	var label: Label = arr[0]
	var rtl: RichTextLabel = RichTextLabel.new()
	_common_connections(rtl, label)
	rtl.scroll_active = false
	rtl.bbcode_enabled = true
	var ls = label.label_settings
	if ls:
		# General
		rtl.add_theme_constant_override(&"line_separation", ls.line_spacing)
		rtl.add_theme_font_override(&"normal_font", ls.font)
		for op: StringName in [&"bold_italics", &"italics", &"mono", &"normal", &"bold"]:
			rtl.add_theme_font_size_override(op + &"_font_size", ls.font_size)
		rtl.add_theme_color_override(&"default_color", ls.font_color)
		# Outline
		rtl.add_theme_constant_override(&"outline_size", ls.outline_size)
		rtl.add_theme_color_override(&"font_outline_color", ls.outline_color)
		# Shadow
		rtl.add_theme_constant_override(&"shadow_outline_size", ls.shadow_size)
		rtl.add_theme_color_override(&"font_shadow_color", ls.shadow_color)
		rtl.add_theme_constant_override(&"shadow_offset_x", ls.shadow_offset.x)
		rtl.add_theme_constant_override(&"shadow_offset_y", ls.shadow_offset.y)

func _to_regular(arr: Array) -> void:
	var rtl: RichTextLabel = arr[0]
	var label: Label = Label.new()
	_common_connections(label, rtl)
	var ls := LabelSettings.new()
	# General
	ls.line_spacing = rtl.get_theme_constant(&"line_separation")
	ls.font = rtl.get_theme_font(&"normal_font")
	ls.font_size = rtl.get_theme_font_size(&"normal_font_size")
	ls.font_color = rtl.get_theme_color(&"default_color")
	# Outline
	ls.outline_size = rtl.get_theme_constant(&"outline_size")
	ls.outline_color = rtl.get_theme_color(&"font_outline_color")
	# Shadow
	ls.shadow_size = rtl.get_theme_constant(&"shadow_outline_size")
	ls.shadow_color = rtl.get_theme_color(&"font_shadow_color")
	ls.shadow_offset = Vector2(
		rtl.get_theme_constant(&"shadow_offset_x"),
		rtl.get_theme_constant(&"shadow_offset_y"),
	)
	label.label_settings = ls

func _common_connections(new: Control, old: Control) -> void:
	new.name = old.name + "-NEW"
	old.add_sibling(new)
	new.owner = old.owner

	for prop_dict: Dictionary in old.get_property_list():
		if prop_dict.name != "name" and new.get(prop_dict.name) != null:
			new.set(prop_dict.name, old.get(prop_dict.name))
