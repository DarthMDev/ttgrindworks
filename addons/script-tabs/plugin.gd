@tool
extends EditorPlugin

const SCRIPT_TABS_SETTING := 'text_editor/script_list/script_tabs_addon/'
const USE_TABS_SETTING := SCRIPT_TABS_SETTING + 'show_script_list_as_tabs'
const HIDE_NATIVE_LIST_SETTING := SCRIPT_TABS_SETTING + 'hide_native_script_list'

var _scripts_tab_container: TabContainer
var _scripts_tab_bar: TabBar
var _scripts_item_list: ItemList
var _scripts_vsplit: VSplitContainer
var _scripts_split_button: Button
var _scripts_split_button_parent: Control
var _prev_state := TabContainerState.new()
var _last_tab_selected = -1
var _last_tab_hovered = -1

var hide_native_list: bool:
	get:
		return EditorInterface.get_editor_settings().get(HIDE_NATIVE_LIST_SETTING)


func _enter_tree() -> void:
	var settings := EditorInterface.get_editor_settings()
	settings.add_property_info({'name': USE_TABS_SETTING, 'type': TYPE_BOOL})
	settings.set_initial_value(USE_TABS_SETTING, true, false)
	if settings.get(USE_TABS_SETTING) == null:
		settings.set(USE_TABS_SETTING, true)
	settings.add_property_info({'name': HIDE_NATIVE_LIST_SETTING, 'type': TYPE_BOOL})
	settings.set_initial_value(HIDE_NATIVE_LIST_SETTING, true, false)
	if settings.get(HIDE_NATIVE_LIST_SETTING) == null:
		settings.set(HIDE_NATIVE_LIST_SETTING, true)
	settings.settings_changed.connect(_on_settings_changed)
	if settings.get(USE_TABS_SETTING):
		_start_plugin()


func _exit_tree() -> void:
	var settings := EditorInterface.get_editor_settings()
	settings.settings_changed.disconnect(_on_settings_changed)
	if settings.get(USE_TABS_SETTING):
		_stop_plugin()


func _on_settings_changed() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings.check_changed_settings_in_group(SCRIPT_TABS_SETTING):
		if USE_TABS_SETTING in settings.get_changed_settings():
			if settings.get(USE_TABS_SETTING) == true:
				_start_plugin()
			else:
				_stop_plugin()
		if (HIDE_NATIVE_LIST_SETTING in settings.get_changed_settings()
				and settings.get(USE_TABS_SETTING) == true):
			if _scripts_item_list:
				var hide_native_list := settings.get(HIDE_NATIVE_LIST_SETTING)
				_scripts_item_list.get_parent().visible = not hide_native_list


func _start_plugin() -> void:
	var script_editor = get_editor_interface().get_script_editor()
	_scripts_tab_container = first_or_null(script_editor.find_children(
			"*", "TabContainer", true, false
		)
	)
	_scripts_item_list = first_or_null(script_editor.find_children(
		"*", "ItemList", true, false
	))
	_scripts_vsplit = _scripts_item_list.get_parent().get_parent()
	_scripts_split_button = find_editor_tooltip(_scripts_vsplit.get_parent(), "Toggle Files Panel")
	while not _scripts_split_button:
		await get_tree().process_frame
		_scripts_split_button = find_editor_tooltip(_scripts_vsplit.get_parent(), "Toggle Files Panel")
	_scripts_split_button_parent = _scripts_split_button.get_parent()

	if _scripts_tab_container:
		_scripts_tab_bar = get_tab_bar_of(_scripts_tab_container)
		_prev_state.save(_scripts_tab_container, _scripts_tab_bar)
		_scripts_tab_container.tabs_visible = true
		_scripts_tab_container.drag_to_rearrange_enabled = true
		_scripts_tab_container.sort_children.connect(_update_tabs)
		var _sbf: StyleBoxFlat = StyleBoxFlat.new()
		_sbf.bg_color = Color(0, 0, 0, 0.4)
		_scripts_tab_container.add_theme_stylebox_override(&"tabbar_background", _sbf)
	if _scripts_tab_bar:
		_scripts_tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
		_scripts_tab_bar.select_with_rmb = true
		_scripts_tab_bar.drag_to_rearrange_enabled = true
		_scripts_tab_bar.tab_close_pressed.connect(_on_tab_close)
		_scripts_tab_bar.tab_rmb_clicked.connect(_on_tab_rmb)
		_scripts_tab_bar.tab_selected.connect(_on_tab_selected)
		_scripts_tab_bar.tab_hovered.connect(_on_tab_hovered)
		_scripts_tab_bar.mouse_exited.connect(_on_tab_bar_mouse_exited)
		_scripts_tab_bar.active_tab_rearranged.connect(_on_active_tab_rearranged)
		_scripts_tab_bar.gui_input.connect(_on_scripts_tab_bar_gui_input)
		
		var sbf: StyleBoxFlat = _scripts_tab_bar.get_theme_stylebox(&"tab_selected").duplicate()
		sbf.border_width_bottom = sbf.border_width_top
		sbf.border_width_top = 0
		sbf.corner_radius_bottom_left = sbf.corner_radius_top_left
		sbf.corner_radius_bottom_right = sbf.corner_radius_top_right
		sbf.corner_radius_top_left = 0
		sbf.corner_radius_top_right = 0
		_scripts_tab_bar.add_theme_stylebox_override(&"tab_selected", sbf)
		sbf = _scripts_tab_bar.get_theme_stylebox(&"tab_unselected").duplicate()
		sbf.bg_color = Color(0, 0, 0, 0.4)
		_scripts_tab_bar.add_theme_stylebox_override(&"tab_unselected", sbf)

	if _scripts_item_list:
		if hide_native_list:
			_scripts_item_list.get_parent().visible = false
		_scripts_item_list.property_list_changed.connect(_on_item_list_property_list_changed)
	if _scripts_vsplit:
		_scripts_vsplit.collapsed = true
		_scripts_vsplit.hide()
	if _scripts_split_button and _scripts_split_button_parent:
		_scripts_split_button_parent.remove_child(_scripts_split_button)
	_update_tabs()


func _stop_plugin() -> void:
	if _scripts_tab_container:
		_scripts_tab_bar = get_tab_bar_of(_scripts_tab_container)
		_prev_state.restore(_scripts_tab_container, _scripts_tab_bar)
		_scripts_tab_container.sort_children.disconnect(_update_tabs)
	if _scripts_item_list:
		if hide_native_list:
			_scripts_item_list.get_parent().visible = true
		_scripts_item_list.property_list_changed.disconnect(_on_item_list_property_list_changed)
	if _scripts_tab_bar:
		_scripts_tab_bar.mouse_exited.disconnect(_on_tab_bar_mouse_exited)
		_scripts_tab_bar.gui_input.disconnect(_on_scripts_tab_bar_gui_input)
		_scripts_tab_bar.tab_close_pressed.disconnect(_on_tab_close)
		_scripts_tab_bar.tab_rmb_clicked.disconnect(_on_tab_rmb)
		_scripts_tab_bar.tab_selected.disconnect(_on_tab_selected)
		_scripts_tab_bar.tab_hovered.disconnect(_on_tab_hovered)
		_scripts_tab_bar.active_tab_rearranged.disconnect(_on_active_tab_rearranged)
	if _scripts_vsplit:
		_scripts_vsplit.collapsed = false
		_scripts_vsplit.show()
	if _scripts_split_button and _scripts_split_button_parent:
		_scripts_split_button_parent.add_child(_scripts_split_button)
		_scripts_split_button_parent.move_child(_scripts_split_button, 0)

func _on_tab_bar_mouse_exited():
	_last_tab_hovered = -1
	

func _on_tab_hovered(idx):
	_last_tab_hovered = idx


func _on_scripts_tab_bar_gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var tab_control = _scripts_tab_container.get_tab_control(_last_tab_hovered)
		var path = ''
		if tab_control:
			path = tab_control.get("metadata/_edit_res_path")
		_scripts_tab_bar.tooltip_text = '' if path == null else path
	if _last_tab_hovered == -1: return
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_MIDDLE:
			return
			#_simulate_item_clicked(_last_tab_hovered, MOUSE_BUTTON_MIDDLE)


func _on_active_tab_rearranged(_idx_to):
	var control = _scripts_tab_container.get_tab_control(_last_tab_selected)
	if not control:
		return
	_scripts_tab_container.move_child(control, _idx_to)
	_scripts_tab_container.current_tab = _scripts_tab_container.current_tab
	_trigger_script_editor_update_script_names()


func _on_tab_selected(tab_idx):
	_last_tab_selected = tab_idx
	var item_idx = _find_list_item_idx_by_tab_idx(tab_idx)
	if item_idx != -1:
		if not _scripts_item_list.is_selected(item_idx):
			var select_scripts_item = func():
				_scripts_item_list.select(item_idx)
				_scripts_item_list.item_selected.emit(item_idx)
			select_scripts_item.call_deferred()


func _on_tab_rmb(tab_idx):
	_simulate_item_clicked(tab_idx, MOUSE_BUTTON_RIGHT)


func _on_tab_close(tab_idx):
	_simulate_item_clicked(tab_idx, MOUSE_BUTTON_MIDDLE)


func _on_item_list_property_list_changed():
	_update_tabs.call_deferred()


func _simulate_item_clicked(tab_idx, mouse_idx):
	if _scripts_item_list:
		var item_idx = _find_list_item_idx_by_tab_idx(tab_idx)
		if item_idx != -1:
			if mouse_idx == MOUSE_BUTTON_MIDDLE:
				_save_tab_state(tab_idx)
			_scripts_item_list.item_clicked.emit(
				item_idx,
				_scripts_item_list.get_local_mouse_position(),
				mouse_idx
			)
			if mouse_idx == MOUSE_BUTTON_MIDDLE:
				_load_tab_state()

var _last_tab := 0
var _last_scroll := -1.0

func _save_tab_state(tab_idx: int):
	_last_tab = _scripts_tab_bar.current_tab
	_last_scroll = -1.0
	
	#Log.dict(self, {
		#tab_idx = tab_idx,
		#_last_tab = _last_tab,
	#})
	
	if _last_tab == (_scripts_tab_bar.tab_count - 1):
		_last_tab -= 1
		return
	
	if tab_idx < _scripts_tab_bar.current_tab:
		_last_tab -= 1
		return
	
	if tab_idx == _last_tab:
		return
	
	var ce := get_current_code_edit()
	if ce:
		_last_scroll = ce.scroll_vertical

func _load_tab_state():
	var _l := _last_tab
	
	for i in 2:
		if not _scripts_tab_bar.tab_count:
			break
		var item_idx = _find_list_item_idx_by_tab_idx(_l)
		
		#Log.dict(self, {
			#i = i,
			#_l = _l,
			#item_idx = item_idx,
		#})
		
		if item_idx != -1:
			_simulate_item_clicked(_l, MOUSE_BUTTON_LEFT)
			_scripts_tab_bar.current_tab = _l
			_scripts_item_list.select(item_idx)
			_scripts_item_list.item_selected.emit(item_idx)
		if _last_scroll >= 0.0:
			var ce := get_current_code_edit()
			if ce:
				ce.scroll_vertical = _last_scroll
		await get_tree().process_frame


func _update_tabs():
	_update_tab_names()
	_update_tab_icons()


func _update_tab_names():
	if not _scripts_tab_container or not _scripts_item_list:
		return

	for item_idx in _scripts_item_list.item_count:
		var tab_idx = _get_item_list_tab_idx(item_idx)
		if tab_idx != -1:
			_scripts_tab_container.set_tab_title(
				tab_idx, _scripts_item_list.get_item_text(item_idx)
			)


func _update_tab_icons():
	if not _scripts_tab_container or not _scripts_item_list:
		return
	
	var script_editor: ScriptEditor = get_editor_interface().get_script_editor()
	var editor_theme: Theme = get_editor_interface().get_editor_theme()
	var all_scripts: Array[Script] = script_editor.get_open_scripts()
	for item_idx in _scripts_item_list.item_count:
		var tab_idx = _get_item_list_tab_idx(item_idx)
		if tab_idx != -1:
			var icon: Texture2D = _scripts_item_list.get_item_icon(item_idx)
			for script: Script in all_scripts:
				if script.resource_path.split('/')[-1] == _scripts_item_list.get_item_text(item_idx).replace("(*)", ""):
					var extracted_icon: Texture2D = extract_script_icon(script)
					if extracted_icon:
						icon = extracted_icon
						_scripts_tab_container.set_tab_icon_max_width(tab_idx, 16)
					elif editor_theme.has_icon(script.get_instance_base_type(), &"EditorIcons"):
						icon = editor_theme.get_icon(script.get_instance_base_type(), &"EditorIcons")
			# var script: Script = _get_item_list_tab_idx(tab_idx)
			_scripts_tab_container.set_tab_icon(
				tab_idx, icon
			)


func _get_item_list_tab_idx(item_idx) -> int:
	var metadata = _scripts_item_list.get_item_metadata(item_idx)
	if not metadata is int:
		return -1
	else:
		return metadata


func _find_list_item_idx_by_tab_idx(tab_idx) -> int:
	for i in _scripts_item_list.item_count:
		if _scripts_item_list.get_item_metadata(i) == tab_idx:
			return i
	return -1


func _trigger_script_editor_update_script_names():
	var script_editor = get_editor_interface().get_script_editor()
	# for now it is the only way to trigger script_edtior._update_script_names
	script_editor.notification(Control.NOTIFICATION_THEME_CHANGED)


func get_current_code_edit() -> CodeEdit:
	return get_editor_interface().get_script_editor().get_current_editor().get_base_editor()


static func first_or_null(arr):
	if len(arr) == 0:
		return null
	return arr[0]


static func get_tab_bar_of(src) -> TabBar:
	for c in src.get_children(true):
		if c is TabBar:
			return c
	return null

static func find_editor_tooltip(c: Node, tooltip: String) -> Control:
	if is_instance_of(c, Control):
		#if c.tooltip_text:
			#print(c.tooltip_text)
		if c.tooltip_text.contains(tooltip):
			return c
	for child in c.get_children():
		var result := find_editor_tooltip(child, tooltip)
		if result != null:
			return result
	return null

static func extract_script_icon(script: Script, limiter: int = 50) -> Texture2D:
	var icon_idx: int = script.source_code.find("@icon(")
	var icon: Texture2D
	if icon_idx != -1 and icon_idx < limiter:
		var modified := script.source_code.substr(icon_idx)
		icon = load(modified.get_slice(")", 0).replace("@icon(", "").replace("\"", ""))

	while icon == null and script.get_base_script():
		script = script.get_base_script()
		icon = extract_script_icon(script, limiter)

	return icon


class TabContainerState:
	var _tabs_visible
	var _drag_to_rearrange_enabled
	var _tab_close_display_policy
	var _select_with_rmb
	
	func save(src: TabContainer, tab_bar: TabBar):
		if src:
			_tabs_visible = src.tabs_visible
		if tab_bar:
			_drag_to_rearrange_enabled = tab_bar.drag_to_rearrange_enabled
			_tab_close_display_policy = tab_bar.tab_close_display_policy
			_select_with_rmb = tab_bar.select_with_rmb
	
	func restore(src: TabContainer, tab_bar: TabBar):
		if src:
			src.tabs_visible = _tabs_visible
		if tab_bar:
			tab_bar.drag_to_rearrange_enabled = _drag_to_rearrange_enabled
			tab_bar.tab_close_display_policy = _tab_close_display_policy
			tab_bar.select_with_rmb = _select_with_rmb
