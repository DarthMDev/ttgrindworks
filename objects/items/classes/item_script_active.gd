extends ItemScript
class_name ItemScriptActive

enum UseFailType {
	PLAYER_STATE,
	CHARGE_COUNT,
	VERIFY,
	NOT_FOCUSED,
	SUCCESS,
}


var item: ItemActive
var is_removing := false

signal s_used
signal s_use_failed
signal s_no_charge_use_failed
signal s_use_canceled


## Runs when item is collected, or game is loaded
func initialize(_item: Item, _object: Node3D) -> void:
	pass

## Runs when item is successfully used
func use() -> void:
	item.play_sound_key(item.SoundType.USE)

func use_failed(from_no_charge := false) -> void:
	item.play_sound_key(item.SoundType.FAILED)
	s_use_failed.emit()
	if from_no_charge:
		s_no_charge_use_failed.emit()

## DO NOT OVERWRITE FUNCTIONS BELOW THIS LINE THANKS :)
func on_collect(_item: Item, object: Node3D) -> void:
	hook_up()
	initialize(_item, object)

func on_load(_item: Item) -> void:
	hook_up()
	initialize(_item, null)

func hook_up() -> void:
	BattleService.s_battle_started.connect(_on_battle_started)
	if not is_instance_valid(Util.get_player()):
		await Util.s_player_assigned
	Util.get_player().active_item_ui.s_use_pressed.connect(attempt_use)
	Util.get_player().stats.s_active_item_changed.connect(check_item)

func attempt_use() -> void:
	var fail_type := is_usable()
	match fail_type:
		UseFailType.SUCCESS:
			item.current_charge = 0
			use()
			s_used.emit()
			Globals.s_pocket_prank_used.emit(item)
			SaveFileService.progress_file.pocket_pranks_used += 1
			if item.one_time_use:
				attempt_disconnect()
			return
		UseFailType.CHARGE_COUNT:
			use_failed(true)
		_:
			use_failed()

## Override this to check if the item can't be used
## Even if we're in the correct use state with a full charge
func validate_use() -> bool:
	return true

## Comprehensive check for all potential use failiures
func is_usable() -> UseFailType:
	if not Util.get_player().stats.current_active_item == item:
		return UseFailType.NOT_FOCUSED
	elif not check_player_state():
		return UseFailType.PLAYER_STATE
	elif not check_charge():
		return UseFailType.CHARGE_COUNT
	elif not validate_use():
		return UseFailType.VERIFY
	return UseFailType.SUCCESS

func check_charge() -> bool:
	if item.needs_full_charge:
		return item.charge_count == item.current_charge
	return true 

## DEPRECATED: THIS FUNCTION WILL BE REMOVED IN A FUTURE UPDATE
## Please use validate_use to check a prank use's validity from now on
func cancel_use() -> void:
	item.current_charge = item.charge_count
	use_failed(false)
	s_use_canceled.emit()

func attempt_disconnect() -> void:
	is_removing = true
	if Util.get_player().stats.current_active_item == item:
		if not Util.get_player().stats.actives_in_reserve.is_empty():
			Util.get_player().stats.current_active_item = Util.get_player().stats.actives_in_reserve.pop_front()
		else:
			Util.get_player().stats.current_active_item = null
	if not Item.ItemTag.DELAYED_FREE in item.tags:
		queue_free()

func charge_item(count := 1) -> void:
	item.current_charge += count

func check_item(new_item: ItemActive) -> void:
	if is_removing: return
	if not new_item == item:
		if not item in Util.get_player().stats.actives_in_reserve:
			attempt_disconnect()

func check_player_state() -> bool:
	var player := Util.get_player()
	
	if item.active_type == ItemActive.ActiveType.BATTLE or item.active_type == ItemActive.ActiveType.ANY:
		if is_instance_valid(BattleService.ongoing_battle):
			return not BattleService.ongoing_battle.is_round_ongoing
	elif item.active_type == ItemActive.ActiveType.REALTIME or item.active_type == ItemActive.ActiveType.ANY:
		return player.controller.current_state.accepts_interaction()
	elif item.active_type == ItemActive.ActiveType.WHENEVER:
		return true
	return false

func _on_battle_started(battle: BattleManager) -> void:
	if battle.battle_node.boss_battle:
		battle.s_battle_ended.connect(charge_item.bind(2))
	elif battle.battle_node.is_punishment_battle:
		return
	else:
		battle.s_battle_ended.connect(charge_item)
