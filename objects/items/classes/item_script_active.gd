extends ItemScript
class_name ItemScriptActive

var item : ItemActive

signal s_used
signal s_use_failed


## Runs when item is collected, or game is loaded
func initialize(_item : Item, _object : Node3D) -> void:
	pass

## Runs when item is successfully used
func use() -> void:
	item.play_sound_key(item.SoundType.USE)
	pass

func use_failed() -> void:
	item.play_sound_key(item.SoundType.FAILED)
	s_use_failed.emit()

## DO NOT OVERWRITE FUNCTIONS BELOW THIS LINE THANKS :)
func on_collect(_item : Item, object : Node3D) -> void:
	hook_up()
	initialize(_item, object)

func on_load(_item : Item) -> void:
	hook_up()
	initialize(_item, null)

func hook_up() -> void:
	BattleService.s_battle_started.connect(_on_battle_started)
	if not is_instance_valid(Util.get_player()):
		await Util.s_player_assigned
	Util.get_player().active_item_ui.s_use_pressed.connect(attempt_use)
	Util.get_player().stats.s_active_item_changed.connect(check_item)

func attempt_use() -> void:
	if item.charge_count == item.current_charge and check_player_state():
		item.current_charge = 0
		use()
		return
	use_failed()

func cancel_use() -> void:
	item.current_charge = item.charge_count
	use_failed()

func attempt_disconnect() -> void:
	queue_free()

func charge_item(count := 1) -> void:
	item.current_charge += count

func check_item(new_item : ItemActive) -> void:
	if not new_item == item:
		attempt_disconnect()

func check_player_state() -> bool:
	var player_state := Util.get_player().state
	
	if item.active_type == ItemActive.ActiveType.BATTLE or item.active_type == ItemActive.ActiveType.ANY:
		if is_instance_valid(BattleService.ongoing_battle):
			return not BattleService.ongoing_battle.is_round_ongoing
	elif item.active_type == ItemActive.ActiveType.REALTIME or item.active_type == ItemActive.ActiveType.ANY:
		return player_state == Player.PlayerState.WALK
	elif item.active_type == ItemActive.ActiveType.WHENEVER:
		return true
	return false

func _on_battle_started(battle : BattleManager) -> void:
	if battle.battle_node.boss_battle:
		battle.s_battle_ended.connect(charge_item.bind(2))
	else:
		battle.s_battle_ended.connect(charge_item)
