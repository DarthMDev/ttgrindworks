extends ItemSpirit

@export var scaling_stat := 'defense'
@export var scaling_factor := -0.01
@export var scaling_jellybean_threshold := 5
@export var jellybean_gain := 1
@export var damage_threshold := 3

var current_damage := 0
var multiplier : StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player = Util.get_player()
	player.stats.hp_lost.connect(give_payout)
	connect_impure_function(apply_penalty, player.stats.s_money_changed)
	if !spirit_purified:
		create_multiplier()
		apply_penalty(player.stats.money)

func give_payout(hploss: int):
	current_damage += hploss
	if current_damage > damage_threshold:
		Util.get_player().stats.add_money(current_damage % damage_threshold)
		current_damage /= damage_threshold
		Util.get_player().boost_queue.queue_text("Compensated!", Color(0.0, 0.602, 0.186))
		AudioManager.play_sound(load("res://audio/sfx/ui/tick_counter.ogg"))

func create_multiplier() -> void:
	multiplier = StatMultiplier.new()
	multiplier.stat = scaling_stat
	multiplier.amount = 0.0
	multiplier.additive = true
	Util.get_player().stats.multipliers.append(multiplier)
	
func apply_penalty(money: int):
	multiplier.amount = floori(money / scaling_jellybean_threshold) * scaling_factor
	
func purify():
	super()
	Util.get_player().stats.multipliers.erase(multiplier)
