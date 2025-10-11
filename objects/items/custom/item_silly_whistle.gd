extends ItemScript

const ProcChance := 0.15

var player: Player
var _last_hp: int

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	player = Util.get_player()
	_last_hp = player.stats.hp
	player.stats.hp_changed.connect(on_hp_changed)

func on_hp_changed(new_hp: int) -> void:
	if new_hp < _last_hp and randf() < player.stats.get_luck_weighted_chance(ProcChance, ProcChance * 1.5, 2.0):
		proc()

	_last_hp = new_hp

func proc() -> void:
	if not player.stats.current_active_item:
		return
	if player.stats.current_active_item.current_charge >= player.stats.current_active_item.charge_count:
		return

	player.stats.charge_active_item(1)
	player.boost_queue.queue_text("Silly Charge!", Color(0.487, 1.0, 0.43, 1.0))
	AudioManager.play_sound(load("res://audio/sfx/items/tt_s_prp_sillyMeterArrow.ogg"), 4.0)
