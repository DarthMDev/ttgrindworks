extends Control

@onready var bar: ProgressBar = %ProgressBar


var current_value := 0.0:
	set(x):
		current_value = clampf(x, 0.0, 100.0)

func set_value(value: float) -> void:
	current_value = value

func _ready() -> void:
	BattleService.s_round_started.connect(on_round_start)
	begin_bar_tween()

#region Aesthetic
const BAR_RANGE := Vector2(0.9, 1.1)
const BAR_SPEED_RANGE := Vector2(0.1, 0.25)
var bar_tween: Tween

func begin_bar_tween() -> void:
	while true:
		var bar_offset := randf_range(BAR_RANGE.x, BAR_RANGE.y)
		var bar_speed := randf_range(BAR_SPEED_RANGE.x, BAR_SPEED_RANGE.y)
		do_bar_tween(100.0 - (current_value * bar_offset), bar_speed)
		await bar_tween.finished

func do_bar_tween(to: float, time: float) -> void:
	bar_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	bar_tween.tween_property(bar, 'value', to, time)
	bar_tween.finished.connect(bar_tween.kill)

#endregion

#region Game Logic
var player: Player:
	get: return Util.get_player()

const REALTIME_RAISE_RATE := 0.15
const BATTLE_ROUND_RATE := 4.0
const DAMAGE_THRESHOLD := Vector2(20.0, 100.0)
const DAMAGE_RANGE := Vector2(0.01, 0.1)
var time_since_cooldown := 0.0


func _process(delta: float) -> void:
	
	if not is_instance_valid(player) or not player.state == Player.PlayerState.WALK:
		return
	
	time_since_cooldown += delta
	var delta_multiplier := 1.0 + time_since_cooldown / 10.0
	set_value(current_value + ((REALTIME_RAISE_RATE * delta) * delta_multiplier))

func get_current_tick() -> int:
	if current_value < DAMAGE_THRESHOLD.x:
		return 0
	var threshold_window := DAMAGE_THRESHOLD.y - DAMAGE_THRESHOLD.x
	var working_value := current_value - DAMAGE_THRESHOLD.x
	var threshold_perc := working_value / threshold_window
	var damage_range := Vector2(float(player.stats.max_hp * DAMAGE_RANGE.x), float(player.stats.max_hp * DAMAGE_RANGE.y))
	var damage_window := damage_range.y - damage_range.x
	var final_damage := damage_range.x + (damage_window * threshold_perc)
	return -floori(final_damage)

func cool_down() -> void:
	set_value(0.0)
	time_since_cooldown = 0.0

func on_damage_timeout() -> void:
	if not player.state == Player.PlayerState.WALK:
		return
	player.quick_heal(get_current_tick(), false)

func on_round_start(_actions) -> void:
	if current_value >= DAMAGE_THRESHOLD.x:
		var battle_action := ActionScriptCallable.new()
		battle_action.callable = battle_movie
		battle_action.user = player
		battle_action.targets = [player]
		BattleService.ongoing_battle.append_action(battle_action)
	current_value += BATTLE_ROUND_RATE

func battle_movie() -> void:
	var manager := BattleService.ongoing_battle
	var battle_node := manager.battle_node
	var targets := manager.current_action.targets
	
	battle_node.focus_character(player)
	manager.show_action_name("You're burning up!")
	player.set_animation('cringe')
	player.quick_heal(get_current_tick())
	await Task.delay(3.25)
	
	await manager.check_pulses(targets)

#endregion
