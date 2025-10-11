extends ItemScript

const UseCost := 0.1

var player: Player
var curr_active_item: ItemActive

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	player = Util.get_player()
	player.stats.s_active_item_changed.connect(on_active_item_changed)
	if player.stats.current_active_item:
		on_active_item_changed(player.stats.current_active_item)

func on_active_item_changed(active_item: ItemActive) -> void:
	if curr_active_item and curr_active_item.node:
		curr_active_item.node.s_no_charge_use_failed.disconnect(on_item_use_fail)
	curr_active_item = active_item
	if curr_active_item and curr_active_item.node:
		curr_active_item.node.s_no_charge_use_failed.connect(on_item_use_fail)

func on_item_use_fail() -> void:
	player.stats.current_active_item.current_charge += 1
	var damage_amount: int = ceili(player.stats.max_hp * UseCost)
	if player.stats.hp > 1 and player.stats.hp - damage_amount <= 0:
		damage_amount = player.stats.hp - 1

	player.quick_heal(-damage_amount, false)
	player.last_damage_source = "Beauracracy"
	player.boost_queue.queue_text("Power Through!", Color(1.0, 0.443, 0.385, 1.0))
	AudioManager.play_sound(load("res://audio/sfx/misc/LB_capacitor_discharge_3.ogg"), 7.0)
	await get_tree().process_frame
	player.active_item_ui.fail_sound_sfx.stop()
