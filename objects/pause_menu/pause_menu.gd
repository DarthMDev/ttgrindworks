extends Control

const SETTINGS_MENU := preload('res://objects/general_ui/settings_menu/settings_menu.tscn')
const SFX_OPEN := preload("res://audio/sfx/ui/GUI_stickerbook_open.ogg")
const SFX_CLOSE := preload("res://audio/sfx/ui/GUI_stickerbook_delete.ogg")
const ANOMALY_ICON := preload("res://objects/player/ui/anomaly_icon.tscn")

@onready var StatInfo: Array = [
	[%Damage, "damage"],
	[%Defense, "defense"],
	[%Evasiveness, "evasiveness"],
	[%Luck, "luck"],
	[%Speed, "speed"],
]

@export var AnimatePauseMenu: bool = true

@export var quest_scrolls: Array[QuestScroll]

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
		stat_array[0].text = '%s: %.2f' % [
			stat_array[1].capitalize(),
			Util.get_player().stats.get_stat(stat_array[1])
		]

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
		if quests.size() < i + 1:
			scroll.hide()
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
	quit_panel.get_node('Panel/GeneralButton').pressed.connect(
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

func _physics_process(_delta : float) -> void:
	if Input.is_action_just_pressed('pause'):
		resume()

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
