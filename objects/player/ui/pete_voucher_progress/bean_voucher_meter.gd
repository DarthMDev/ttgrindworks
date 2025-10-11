@tool
extends Control

@export_category('Demo')
@export_tool_button("Add 5") var add5 = add_5
@export_tool_button("Add 30") var add30 = add_30
@export_tool_button("Add 90") var add90 = add_90
@export_tool_button("Add 300") var add300 = add_300
@export_tool_button("Add 3000") var add3000 = add_3000

const ROTATION_SPEED := 100.0
const REWARD_QUOTA := 30
const PITCH_SHIFT_PER_COMBO := 0.1

var excess_beans: float:
	set(x): %ProgressBar.value = x
	get: return %ProgressBar.value

var colors: Dictionary[int, Color] = {
	0: Color(1.0, 0.0, 0.0),
	1: Color(0.5, 1.0, 0.5),
	2: Color(0.5, 1.0, 1.0),
	3: Color(1.0, 1.0, 0.4),
	4: Color(0.4, 0.4, 1.0),
	5: Color(1.0, 0.5, 1.0)
}

var bar_tween: Tween
var rewards := 0
var current_combo := 0
var popin_tween: Tween


func _ready() -> void:
	var voucher_tween := create_tween().set_loops()
	for key in colors.keys():
		voucher_tween.tween_property(%Voucher3D, 'modulate', colors[key], 2.0)
		voucher_tween.parallel().tween_property(%ProgressBar['theme_override_styles/fill'], 'bg_color', colors[key], 2.0)
		voucher_tween.parallel().tween_property(%ProgressBar['theme_override_styles/background'], 'bg_color', colors[key].darkened(0.5), 2.0)
	%ProgressBar.max_value = REWARD_QUOTA
	excess_beans = 0

func _process(delta: float) -> void:
	%Voucher3D.rotation_degrees.y += delta * ROTATION_SPEED
	if %Voucher3D.rotation_degrees.y >= 360.0:
		%Voucher3D.rotation_degrees.y -= 360.0
	
	%ProgressLabel.set_text("%d/%d" % [roundi(excess_beans), REWARD_QUOTA])

func ui_in() -> void:
	if popin_tween and popin_tween.is_running():
		popin_tween.kill()
	var up_pos := 578.0
	popin_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	popin_tween.tween_property(%Meter, 'position:y', up_pos, 0.25)
	popin_tween.finished.connect(popin_tween.kill)

func ui_out() -> void:
	if popin_tween and popin_tween.is_running():
		popin_tween.kill()
	var down_pos := 667.0
	popin_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	popin_tween.tween_property(%Meter, 'position:y', down_pos, 0.5)
	popin_tween.finished.connect(popin_tween.kill)

func set_ui_active(active: bool) -> void:
	if active:
		ui_in()
	else:
		await get_tree().physics_frame
		if not bar_tween or not bar_tween.is_running():
			ui_out()

func increase_beans(amount: int) -> void:
	set_ui_active(true)
	if bar_tween and bar_tween.is_running():
		bar_tween.custom_step(1000.0)
		bar_tween.kill()
	do_increment_tween(ceili(excess_beans) + amount)

func do_increment_tween(new_bean_count: int) -> void:
	if bar_tween and bar_tween.is_running():
		bar_tween.custom_step(1000.0)
		bar_tween.kill()
	
	var min_fill_time := 0.2
	var inc_fill_time := -0.1
	var bc := new_bean_count
	var fill_time := 1.0
	while bc > REWARD_QUOTA and fill_time > min_fill_time:
		fill_time += inc_fill_time
		bc -= REWARD_QUOTA
	
	bar_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	bar_tween.tween_interval(0.5)
	while new_bean_count >= REWARD_QUOTA:
		bar_tween.tween_property(%ProgressBar, 'value', REWARD_QUOTA, fill_time)
		bar_tween.tween_callback(queue_reward)
		bar_tween.tween_callback(%ProgressBar.set_value.bind(0))
		new_bean_count -= REWARD_QUOTA
	bar_tween.tween_property(%ProgressBar, 'value', new_bean_count, fill_time)
	bar_tween.tween_callback(%ProgressBar.set_value.bind(new_bean_count))
	bar_tween.tween_interval(2.0)
	
	bar_tween.finished.connect(bar_tween.kill)
	bar_tween.finished.connect(set_ui_active.bind(false))


func queue_reward(count := 1) -> void:
	rewards += count
	if %RewardCooldown.is_stopped():
		reward_cooldown_timeout()

func reward_cooldown_timeout() -> void:
	if rewards > 0:
		rewards -= 1
		give_reward()
		%TickSound.pitch_scale = 1.0 + minf(PITCH_SHIFT_PER_COMBO * current_combo, 5.0)
		current_combo += 1
	else:
		current_combo = 0
		%TickSound.pitch_scale = 1.0

func give_reward() -> void:
	var reward_index: int
	if not Engine.is_editor_hint():
		reward_index = RNG.channel(RNG.ChannelOverfillBeanVouchers).randi_range(0, colors.size() - 1)
		Util.get_player().stats.bean_vouchers[reward_index] += 1
	else:
		reward_index = randi_range(0, colors.size() - 1)
	
	var color := colors[reward_index]
	var reward_popup: Control = %RewardPopup.duplicate()
	var scaler: Control = reward_popup.get_node('Scaler')
	reward_popup.get_node('Scaler/TextureRect').self_modulate = color
	var reward_label: Label = reward_popup.get_node('Scaler/Label')
	var label_settings: LabelSettings = reward_label.label_settings.duplicate()
	label_settings.font_color = color
	label_settings.outline_color = color.darkened(0.8)
	reward_label.label_settings = label_settings
	reward_popup.show()
	add_child(reward_popup)
	move_child(reward_popup, 0)
	%TickSound.play()
	%RewardCooldown.start()
	
	var base_pos := 576.0
	var up_pos := 250.0
	reward_popup.position.y = base_pos
	var reward_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	reward_tween.tween_property(reward_popup, 'position:y', up_pos, 3.0)
	reward_tween.parallel().tween_property(scaler, 'scale', Vector2.ONE, 0.5).set_delay(0.15)
	reward_tween.set_ease(Tween.EASE_IN)
	reward_tween.parallel().tween_property(reward_popup, 'modulate:a', 0.0, 1.0).set_delay(2.0)
	reward_tween.parallel().tween_property(scaler, 'scale', Vector2.ONE * 0.01, 0.95).set_delay(2.0)
	reward_tween.finished.connect(reward_popup.queue_free)
	reward_tween.finished.connect(reward_tween.kill)
	reward_tween.set_speed_scale(1.0 + (PITCH_SHIFT_PER_COMBO * rewards))


func add_5() -> void:
	increase_beans(5)

func add_30() -> void:
	increase_beans(30)

func add_90() -> void:
	increase_beans(90)

func add_300() -> void:
	increase_beans(300)

func add_3000() -> void:
	increase_beans(3000)
