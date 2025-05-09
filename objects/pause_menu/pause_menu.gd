extends Control

const SETTINGS_MENU := preload('res://objects/general_ui/settings_menu/settings_menu.tscn')
const SFX_OPEN := preload("res://audio/sfx/ui/GUI_stickerbook_open.ogg")
const SFX_CLOSE := preload("res://audio/sfx/ui/GUI_stickerbook_delete.ogg")
const SFX_STAT_CHANGE := preload("res://audio/sfx/ui/sfx_pop.ogg")
const ANOMALY_ICON := preload("res://objects/player/ui/anomaly_icon.tscn")


@onready var StatInfo: Array = [
	[%Damage, "damage"],
	[%Defense, "defense"],
	[%Evasiveness, "evasiveness"],
	[%Luck, "luck"],
	[%Speed, "speed"],
]
@onready var menu_pages := %Pages

@export var AnimatePauseMenu: bool = true

@export var quest_scrolls: Array[QuestScroll]

var page_current := 0:
	set(x):
		if not is_node_ready(): await ready
		var force_dir := -1
		if x < 0:
			x = menu_pages.get_child_count() - 1
			force_dir = 0
		elif x >= menu_pages.get_child_count():
			x = 0
			force_dir = 1
		
		set_page_view(x)
		
		if force_dir == -1:
			if x > page_current: force_dir = 1
			else: force_dir = 0
		
		do_page_transition(menu_pages.get_child(page_current), menu_pages.get_child(x), force_dir)
		
		page_current = x


func _ready() -> void:
	hide()
	get_tree().paused = true
	get_player_info()
	
	if is_instance_valid(Util.floor_manager):
		if Util.floor_manager.floor_variant:
			%FloorLabel.set_text(Util.floor_manager.floor_variant.floor_name)
			for floor_icon: TextureRect in [%FacilityIcon, %FacilityIcon2]:
				floor_icon.texture = Util.floor_manager.floor_variant.floor_icon
			if Util.floor_manager.anomalies:
				for floor_mod: FloorModifier in Util.floor_manager.anomalies:
					var new_icon: Control = ANOMALY_ICON.instantiate()
					new_icon.instantiated_anomaly = floor_mod
					%AnomaliesContainer.add_child(new_icon)
				# Move it up to account for the anomaly icons
				%FloorMainContainer.position.y -= 68
	else:
		%FloorMainContainer.hide()

	apply_stat_labels()
	apply_stat_changes()
	sync_reward()
	%VersionLabel.text = Globals.VERSION_NUMBER
	
	AudioManager.set_fx_music_lpfilter()
	AudioManager.play_sound(SFX_OPEN)

	if AnimatePauseMenu:
		$AnimationPlayer.play("pause_on")
		show()
	
	Globals.s_game_paused.emit(self)

func apply_stat_labels() -> void:
	for stat_array: Array in StatInfo:
		stat_array[0].text = '%s: %d%%' % [
			stat_array[1].capitalize(),
			Util.get_player().stats.get_stat_as_percent(stat_array[1])
		]

func apply_stat_changes() -> void:
	var stat_up_color := Color("4de64d")
	var stat_down_color := Color("e64d4d")
	var stat_change_labels : Array[Label] = [
		%DamageChange, %DefenseChange, %EvasivenessChange, %LuckChange, %SpeedChange
	]
	for label : Label in stat_change_labels:
		var stat_change := get_stat_change(label.name.to_lower().trim_suffix('change'))
		if is_equal_approx(stat_change, 0.0):
			label.set_text("")
			continue
		var stat_change_txt := "%d%%" % roundi(stat_change * 100.0)
		if stat_change >= 0.0:
			label.set_text("+%s" % stat_change_txt.trim_suffix('0'))
			label.label_settings.font_color = stat_up_color
		else: 
			label.set_text("%s" % stat_change_txt.trim_suffix('0'))
			label.label_settings.font_color = stat_down_color
		do_stat_change_flash(label, 0.1 * stat_change_labels.find(label))
	Util.get_player().stats.start_stat_monitors()

func get_stat_change(stat : String) -> float:
	var stats := Util.get_player().stats
	if not stat in stats.prev_stats:
		return stats.get_stat(stat)
	return stats.get_stat(stat) - stats.prev_stats[stat]

func do_stat_change_flash(label : Label, delay := 0.0) -> void:
	label.pivot_offset = Vector2(label.size.x / 2.0, label.size.y / 2.0)
	label.scale = Vector2.ONE * 0.01
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(delay)
	tween.tween_callback(
		func():
			var player := AudioManager.play_sound(SFX_STAT_CHANGE)
			player.pitch_scale = 1.0 + delay / 2.0
	)
	tween.tween_property(label.label_settings, 'font_color', Color.WHITE, 0.2)
	tween.parallel().tween_property(label, 'scale', Vector2.ONE * 1.1, 0.2)
	tween.tween_interval(0.01)
	tween.tween_property(label.label_settings, 'font_color', label.label_settings.font_color, 0.2)
	tween.parallel().tween_property(label, 'scale', Vector2.ONE, 0.2)
	tween.finished.connect(tween.kill)

func did_stats_change() -> bool:
	var stats := Util.get_player().stats
	for stat in stats.prev_stats:
		if not is_equal_approx(stats.get_stat(stat), stats.prev_stats[stat]):
			return true
	return false

func _exit_tree() -> void:
	AudioManager.reset_fx_music_lpfilter()
	AudioManager.play_sound(SFX_CLOSE)

func get_player_info() -> void:
	var player := Util.get_player()
	if not is_instance_valid(player):
		return
	
	# Get player quests
	var quests: Array[Quest] = player.stats.quests
	for i in quest_scrolls.size():
		var scroll := quest_scrolls[i]
		scroll.s_quest_completed.connect(on_quest_complete)
		if quests.size() < i + 1:
			scroll.set_elements_visible(false)
		else:
			scroll.quest = quests[i]
		
		# Hook up player rerolls
		scroll.set_rerolls(player.stats.quest_rerolls)
		scroll.s_quest_rerolled.connect(on_quest_rerolled)
	
	# Make quests uncompletable if not in walk state
	if not player.state == Player.PlayerState.WALK:
		for scroll in quest_scrolls:
			scroll.collect_button.set_disabled(true)

func resume() -> void:
	get_tree().paused = false
	queue_free()

func quit() -> void:
	var quit_panel := Util.acknowledge("Quit game?")
	quit_panel.cancelable = true
	quit_panel.get_node('Panel/ConfirmButton').pressed.connect(
		func():
			SceneLoader.clear_persistent_nodes()
			SceneLoader.load_into_scene("res://scenes/title_screen/title_screen.tscn")
			resume()
	)
	quit_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	tree_exited.connect(quit_panel.queue_free)

func open_settings() -> void:
	var settings_menu: UIPanel = SETTINGS_MENU.instantiate()
	add_child(settings_menu)
	tree_exited.connect(settings_menu.queue_free)

func on_quest_rerolled() -> void:
	Util.get_player().stats.quest_rerolls -= 1
	for scroll: QuestScroll in quest_scrolls:
		scroll.set_rerolls(Util.get_player().stats.quest_rerolls)

func on_quest_complete() -> void:
	if did_stats_change():
		apply_stat_labels()
		apply_stat_changes()
	%GagPanel.refresh()


func _physics_process(_delta : float) -> void:
	if Input.is_action_just_pressed('pause'):
		resume()
	if Input.is_action_just_pressed('move_left'):
		view_prev_page()
	if Input.is_action_just_pressed('move_right'):
		view_next_page()

func view_next_page() -> void:
	if page_transition and page_transition.is_running():
		return
	page_current += 1

func view_prev_page() -> void:
	if page_transition and page_transition.is_running():
		return
	page_current -= 1

func set_page_view(index : int) -> void:
	for i in menu_pages.get_child_count():
		menu_pages.get_child(i).visible = index == i

var page_transition : Tween
func do_page_transition(old_page : Control, new_page : Control, side := 0) -> void:
	old_page.show()
	if page_transition and page_transition.is_running():
		page_transition.kill()
	page_transition = create_tween().set_trans(Tween.TRANS_QUAD)
	
	old_page.position.x = 0.0
	if side == 0:
		new_page.position.x = -new_page.size.x
		page_transition.tween_property(old_page, 'position:x', old_page.size.x, 0.4)
		page_transition.parallel().tween_property(new_page, 'position:x', 25.0, 0.4)
	else:
		page_transition.tween_property(old_page, 'position:x', -old_page.size.x, 0.4)
		page_transition.parallel().tween_property(new_page, 'position:x', -25.0, 0.4)
		new_page.position.x = old_page.size.x
	page_transition.tween_property(new_page, 'position:x', 0.0, 0.1)
	page_transition.finished.connect(
		func():
			old_page.hide()
			page_transition.kill()
	)

#region Reward Display
func sync_reward() -> void:
	var game_floor := Util.floor_manager
	if is_instance_valid(game_floor) and game_floor.floor_variant and game_floor.floor_variant.reward:
			set_reward(game_floor.floor_variant.reward)
			%NoReward.hide()
	else:
		%NoReward.show()

func set_reward(item: Item) -> void:
	# Add new reward to menu
	var reward_model = item.model.instantiate()
	%RewardView.camera_position_offset = item.ui_cam_offset
	%RewardView.node = reward_model
	%RewardView.want_spin_tween = item.want_ui_spin
	
	# Let item set itself up
	if reward_model.has_method('setup'):
		reward_model.setup(item)

	%RewardView.mouse_entered.connect(hover_floor_reward.bind(item))
	%RewardView.mouse_exited.connect(HoverManager.stop_hover)

func hover_floor_reward(item: Item) -> void:
	Util.do_item_hover(item)
#endregion
