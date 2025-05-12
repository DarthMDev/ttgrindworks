extends ItemScript

# This item runs a x second battle timer on every round
# And shuffles the order of gags on the menu


## Battle Timer created by Util
var timer: GameTimer


func on_collect(_item: Item, _model: Node3D) -> void:
	setup()
	Util.get_player().stats.battle_timers.append(10)

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

## Connect the gag track elements up to be shuffled
func on_battle_start(manager: BattleManager) -> void:
	await manager.s_ui_initialized
	initialize_ui(manager)

func initialize_ui(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	for element: Control in ui.gag_tracks.get_children():
		element.s_refreshing.connect(on_track_refresh)
		element.refresh()
	
	# Also run the round reset method for this first round
	ui.s_turn_complete.connect(on_turn_complete)

## Shuffles the gag order of each track
func on_track_refresh(element: Control) -> void:
	var unlocked: int = element.unlocked
	if unlocked > 0:
		element.gags = element.gags.slice(0,unlocked)
		element.gags.shuffle()

func on_turn_complete(_gags: Array[ToonAttack]) -> void:
	if is_instance_valid(timer) and not timer.is_queued_for_deletion():
		timer.queue_free()
