extends Sprite3D

const MAX_VOUCHER := 5
const UPROLL_CHANCE := 4

var voucher_index := -1
var player: Player:
	get: return Util.get_player()

var colors: Dictionary[int, Color] = {
	0: Color(1.0, 0.0, 0.0),
	1: Color(0.5, 1.0, 0.5),
	2: Color(0.5, 1.0, 1.0),
	3: Color(1.0, 1.0, 0.4),
	4: Color(0.4, 0.4, 1.0),
	5: Color(1.0, 0.5, 1.0)
}
var values: Array[int] = [5, 7, 9, 12, 15, 20]

func setup(item: Item) -> void:
	if not is_instance_valid(player) or not player.gags_cost_beans:
		item.reroll()
		return
	
	if not item.arbitrary_data.has('voucher_index'):
		roll_for_index()
		item.arbitrary_data['voucher_index'] = voucher_index
		item.big_description = "Adds + %d jellybeans" % values[voucher_index]
		item.custom_shop_price = values[voucher_index] / 2
	voucher_index = item.arbitrary_data['voucher_index']
	color_voucher()

func roll_for_index() -> void:
	voucher_index = 0
	while voucher_index < MAX_VOUCHER and not RNG.channel(RNG.ChannelBeanVouchers).randi() % UPROLL_CHANCE == 0:
		voucher_index += 1

func collect() -> void:
	player.stats.bean_vouchers[voucher_index] += 1

func color_voucher() -> void:
	modulate = colors[voucher_index]

func modify(ui: Sprite3D) -> void:
	ui.modulate = modulate
